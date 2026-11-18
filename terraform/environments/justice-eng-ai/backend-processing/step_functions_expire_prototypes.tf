# Scheduled removal of dormant prototypes: those not redeployed for a set number of days.
#
# A state machine built with the step_function_builder module runs
# scripts/maintenance/expire_prototypes.py in a dedicated script-runner task. For each
# prototype whose current image was deployed more than the set number of days ago (every
# redeploy resets the age, so prototypes still being worked on are kept), it deletes
# all data held for its AppID (ECS service, listener rules, target group, task definitions,
# log group, prototype table, DNS record, ECR images, S3 packages and build-details items),
# writes a JSON line per prototype to a deletion log group and posts a report of the removed
# AppIDs to Slack through the job-completion topic. Owners are emailed through GOV.UK Notify
# (the build-deployed email template, copied to the team mailbox) a set number of days before
# their prototype is deleted, and again once it has been; a prototype is only deleted after
# its owner has had the full warning period. The web UI file system (EFS) is never
# mounted, so Builder and Forge files are kept.
#
# The settings come from the root application_variables.json:
#
#   prototype_expiry_enabled        true switches the schedule on, false leaves it disabled
#   prototype_expiry_schedule       EventBridge cron expression, evaluated in UK time,
#                                   e.g. "cron(0 3 * * ? *)"
#   prototype_expiry_max_age_days   prototypes whose image was deployed more than this many days ago are removed
#   prototype_expiry_warning_days   owners are warned this many days before removal (0 to the max age;
#                                   0 sends no warning, only the email after removal)
#
# Nothing is created unless prototype_expiry_schedule is set for the environment.

locals {
  expiry_account_data = local.application_data.accounts[local.environment]
  expiry_create       = try(local.expiry_account_data.prototype_expiry_schedule, null) != null

  expiry_enabled      = try(local.expiry_account_data.prototype_expiry_enabled, false)
  expiry_schedule     = try(local.expiry_account_data.prototype_expiry_schedule, "")
  expiry_max_age_days = try(local.expiry_account_data.prototype_expiry_max_age_days, null)
  expiry_warning_days = try(local.expiry_account_data.prototype_expiry_warning_days, null)

  expiry_name                 = "${local.application_name}-expire-prototypes"
  expiry_task_family          = local.expiry_name
  expiry_task_definition_arns = ["arn:${data.aws_partition.current.partition}:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:task-definition/${local.expiry_task_family}:*"]
  expiry_log_group_name       = "/${local.application_name}/prototype-expiry"

  expiry_variables = [
    { name = "ENVIRONMENT", value = local.environment },
    { name = "AWS_REGION", value = data.aws_region.current.region },
    { name = "TABLE", value = aws_dynamodb_table.build_review.name },
    { name = "REPOSITORY", value = aws_ecr_repository.user_applications.name },
    { name = "BUCKET", value = aws_s3_bucket.staging_bucket.id },
    { name = "S3_FOLDER", value = local.s3_folder },
    { name = "PROTOTYPE_CLUSTER", value = data.aws_ecs_cluster.prototype_deployment.cluster_name },
    { name = "PROTOTYPE_LOAD_BALANCER", value = data.aws_lb.prototype_deployment.name },
    { name = "HOSTED_ZONE_ID", value = data.aws_route53_zone.prototype_deployment.zone_id },
    { name = "MAX_AGE_DAYS", value = tostring(local.expiry_max_age_days) },
    { name = "TOPIC_ARN", value = aws_sns_topic.job_completion.arn },
    { name = "LOG_GROUP", value = local.expiry_log_group_name },
    { name = "WARNING_DAYS", value = tostring(local.expiry_warning_days) },
    { name = "NOTIFY_TEMPLATE_ID", value = local.expiry_account_data.notify_template_id },
    { name = "CC_EMAIL", value = local.notify_cc_email },
    { name = "BUILDER_URL", value = local.notify_builder_url },
  ]
}

resource "terraform_data" "expiry_guard" {
  count = local.expiry_create ? 1 : 0

  lifecycle {
    precondition {
      condition     = can(regex("^cron\\([^ ()]+( [^ ()]+){5}\\)$", local.expiry_schedule))
      error_message = "prototype_expiry_schedule must be an EventBridge cron expression with six fields, e.g. cron(0 3 * * ? *)."
    }

    precondition {
      condition     = try(floor(local.expiry_max_age_days) == local.expiry_max_age_days && local.expiry_max_age_days >= 1, false)
      error_message = "prototype_expiry_max_age_days must be set to a whole number of days of 1 or more when prototype_expiry_schedule is set."
    }

    precondition {
      condition     = try(floor(local.expiry_warning_days) == local.expiry_warning_days && local.expiry_warning_days >= 0 && local.expiry_warning_days <= local.expiry_max_age_days, false)
      error_message = "prototype_expiry_warning_days must be set to a whole number of days from 0 to prototype_expiry_max_age_days when prototype_expiry_schedule is set."
    }
  }
}

# ---------- Deletion log ----------

resource "aws_cloudwatch_log_group" "prototype_expiry" {
  # checkov:skip=CKV_AWS_158:Encrypted at rest with the AWS-managed CloudWatch Logs KMS key, like the other log groups here.
  count = local.expiry_create ? 1 : 0

  name              = local.expiry_log_group_name
  retention_in_days = 3653
  tags              = local.tags
}

# ---------- Network ----------

resource "aws_security_group" "expire_prototypes" {
  #checkov:skip=CKV2_AWS_5:Attached at runtime by the Step Functions ecs:runTask network configuration, not by a Terraform-managed resource.
  count = local.expiry_create ? 1 : 0

  name        = "${local.expiry_name}-ecs"
  description = "Controls egress for the prototype expiry task"
  vpc_id      = data.aws_vpc.vpc.id
  tags        = merge(local.tags, { Name = "${local.expiry_name}-ecs" })
}

resource "aws_vpc_security_group_egress_rule" "expire_prototypes_https" {
  count = local.expiry_create ? 1 : 0

  security_group_id = aws_security_group.expire_prototypes[0].id
  description       = "HTTPS egress for AWS APIs"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# ---------- Task role ----------

resource "aws_iam_role" "expire_prototypes_task" {
  count = local.expiry_create ? 1 : 0

  name               = "${substr(local.expiry_name, 0, 55)}-task"
  assume_role_policy = data.aws_iam_policy_document.script_runner_ecs_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "expire_prototypes_task" {
  statement {
    sid       = "DeleteBuildRecords"
    effect    = "Allow"
    actions   = ["dynamodb:Query", "dynamodb:Scan", "dynamodb:BatchWriteItem"]
    resources = [aws_dynamodb_table.build_review.arn]
  }

  statement {
    sid       = "DeletePrototypeTables"
    effect    = "Allow"
    actions   = ["dynamodb:DeleteTable"]
    resources = [local.prototype_app_table_arn_pattern]
  }

  statement {
    sid       = "DeletePrototypeImages"
    effect    = "Allow"
    actions   = ["ecr:ListImages", "ecr:BatchDeleteImage"]
    resources = [aws_ecr_repository.user_applications.arn]
  }

  statement {
    sid       = "ListStagingBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:ListBucketVersions"]
    resources = [aws_s3_bucket.staging_bucket.arn]
  }

  statement {
    sid       = "DeletePrototypePackages"
    effect    = "Allow"
    actions   = ["s3:DeleteObject", "s3:DeleteObjectVersion"]
    resources = ["${aws_s3_bucket.staging_bucket.arn}/*"]
  }

  statement {
    sid    = "DeletePrototypeServices"
    effect = "Allow"
    actions = [
      "ecs:DescribeServices",
      "ecs:ListServices",
      "ecs:DeleteService",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:service/${data.aws_ecs_cluster.prototype_deployment.cluster_name}/*",
      data.aws_ecs_cluster.prototype_deployment.arn,
    ]
  }

  # The owner warning is recorded as tags on the prototype's service.
  statement {
    sid    = "RecordPrototypeWarnings"
    effect = "Allow"
    actions = [
      "ecs:ListTagsForResource",
      "ecs:TagResource",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:service/${data.aws_ecs_cluster.prototype_deployment.cluster_name}/*"]
  }

  statement {
    sid       = "ReadPrototypeTaskDefinitions"
    effect    = "Allow"
    actions   = ["ecs:DescribeTaskDefinition", "ecs:ListTaskDefinitions"]
    resources = ["*"]
  }

  # DeregisterTaskDefinition has no resource type, so it can only be granted on "*". The
  # script only deregisters prototype-* families, and deleting stays scoped to them below.
  statement {
    sid       = "DeregisterPrototypeTaskDefinitions"
    effect    = "Allow"
    actions   = ["ecs:DeregisterTaskDefinition"]
    resources = ["*"]
  }

  statement {
    sid       = "DeletePrototypeTaskDefinitions"
    effect    = "Allow"
    actions   = ["ecs:DeleteTaskDefinitions"]
    resources = ["arn:${data.aws_partition.current.partition}:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:task-definition/prototype-*:*"]
  }

  statement {
    sid    = "DescribeLoadBalancing"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DeletePrototypeRouting"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:DeleteTargetGroup",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:elasticloadbalancing:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:targetgroup/prototype-*/*",
      "arn:${data.aws_partition.current.partition}:elasticloadbalancing:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:listener-rule/app/${data.aws_lb.prototype_deployment.name}/*/*/*",
    ]
  }

  statement {
    sid     = "DeletePrototypeLogGroups"
    effect  = "Allow"
    actions = ["logs:DeleteLogGroup"]
    resources = [
      "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:prototype-*",
      "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:prototype-*:*",
    ]
  }

  statement {
    sid       = "WriteDeletionLog"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:${local.expiry_log_group_name}:*"]
  }

  statement {
    sid       = "DeletePrototypeDnsRecords"
    effect    = "Allow"
    actions   = ["route53:ListResourceRecordSets", "route53:ChangeResourceRecordSets"]
    resources = [data.aws_route53_zone.prototype_deployment.arn]
  }

  statement {
    sid       = "PostSlackReport"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.job_completion.arn]
  }

  statement {
    sid       = "UseJobCompletionTopicKey"
    effect    = "Allow"
    actions   = ["kms:GenerateDataKey", "kms:Decrypt"]
    resources = [aws_kms_key.job_completion.arn]
  }
}

resource "aws_iam_role_policy" "expire_prototypes_task" {
  count = local.expiry_create ? 1 : 0

  name   = "${local.expiry_name}-task"
  role   = aws_iam_role.expire_prototypes_task[0].id
  policy = data.aws_iam_policy_document.expire_prototypes_task.json
}

# ---------- Task definition ----------

# No volumes: the task cannot reach the web UI file system.
resource "aws_ecs_task_definition" "expire_prototypes" {
  count = local.expiry_create ? 1 : 0

  family                   = local.expiry_task_family
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = local.script_runner_task_cpu
  memory                   = local.script_runner_task_memory
  execution_role_arn       = aws_iam_role.script_runner_ecs_execution.arn
  task_role_arn            = aws_iam_role.expire_prototypes_task[0].arn
  tags                     = local.tags

  container_definitions = jsonencode([local.script_runner_container_definition])

  depends_on = [terraform_data.expiry_guard]
}

# ---------- State machine ----------

module "step_functions_expire_prototypes" {
  count  = local.expiry_create ? 1 : 0
  source = "../modules/step_function_builder"

  # Every step can be run again, but a failed run is left for the next schedule rather than retried.
  step_function_retry_attempts = 0
  name                         = local.expiry_name
  execution_role_arn           = aws_iam_role.step_functions_common.arn
  steps = [{
    name            = "expire_prototypes"
    type            = "script_runner"
    script_path     = "scripts/maintenance/expire_prototypes.py"
    shell_type      = "python3"
    variables       = local.expiry_variables
    timeout_seconds = 10800
  }]
  script_runner = {
    cluster_arn            = aws_ecs_cluster.script_runner.arn
    task_definition_family = local.expiry_task_family
    container_name         = "script-runner"
    subnets                = data.terraform_remote_state.justice_eng_ai.outputs.private_subnet_ids
    security_groups        = [aws_security_group.expire_prototypes[0].id]
    assign_public_ip       = "DISABLED"
    execution_role_arn     = aws_iam_role.script_runner_ecs_execution.arn
    task_role_arn          = aws_iam_role.expire_prototypes_task[0].arn
    launch_type            = "FARGATE"
  }
  tags = local.tags

  depends_on = [
    aws_iam_role_policy.step_functions_common,
    aws_iam_role_policy.expire_prototypes_task,
    aws_ecs_task_definition.expire_prototypes,
    aws_cloudwatch_log_group.prototype_expiry,
  ]
}

# ---------- Schedule ----------

resource "aws_iam_role" "expire_prototypes_scheduler" {
  count = local.expiry_create ? 1 : 0

  name               = "${local.expiry_name}-scheduler"
  assume_role_policy = data.aws_iam_policy_document.usage_report_scheduler_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "expire_prototypes_scheduler" {
  count = local.expiry_create ? 1 : 0

  name = "${local.expiry_name}-start"
  role = aws_iam_role.expire_prototypes_scheduler[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "StartPrototypeExpiry"
      Effect   = "Allow"
      Action   = ["states:StartExecution"]
      Resource = [module.step_functions_expire_prototypes[0].arn]
    }]
  })
}

resource "aws_scheduler_schedule" "expire_prototypes" {
  count = local.expiry_create ? 1 : 0

  name                         = local.expiry_name
  description                  = "Removes prototypes not redeployed for more than ${local.expiry_max_age_days} days from the ${local.environment} environment."
  schedule_expression          = local.expiry_schedule
  schedule_expression_timezone = "Europe/London"
  state                        = local.expiry_enabled ? "ENABLED" : "DISABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = module.step_functions_expire_prototypes[0].arn
    role_arn = aws_iam_role.expire_prototypes_scheduler[0].arn
    input    = "{}"
  }
}
