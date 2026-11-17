# Scheduled wipe of every piece of data in an environment (development and test only).
#
# A state machine built with the step_function_builder module runs
# scripts/maintenance/wipe_environment.py in a dedicated script-runner task. The schedule
# comes from the root application_variables.json:
#
#   environment_wipe_enabled   true switches the schedule on, false leaves it disabled
#   environment_wipe_schedule  EventBridge cron expression, evaluated in UK time,
#                              e.g. "cron(0 2 ? * SUN *)" or "cron(0 2 ? * MON-FRI *)"
#   environment_wipe_efs       true also empties the web UI file system (Builder and Forge files)
#
# Nothing is created unless those keys are set, and they must not be set for preproduction
# or production. The plan fails if they are, and the script refuses to run there as well.

locals {
  wipe_environments = ["development", "test"]
  wipe_account_data = local.application_data.accounts[local.environment]
  wipe_keys_set     = try(local.wipe_account_data.environment_wipe_schedule, null) != null
  wipe_create       = local.wipe_keys_set && contains(local.wipe_environments, local.environment)

  wipe_enabled  = try(local.wipe_account_data.environment_wipe_enabled, false)
  wipe_schedule = try(local.wipe_account_data.environment_wipe_schedule, "")
  wipe_efs      = local.wipe_create && try(local.wipe_account_data.environment_wipe_efs, false)

  wipe_name                 = "${local.application_name}-wipe-environment"
  wipe_task_family          = local.wipe_name
  wipe_task_definition_arns = ["arn:${data.aws_partition.current.partition}:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:task-definition/${local.wipe_task_family}:*"]
  wipe_efs_mount_path       = "/mnt/efs"
  wipe_ui_services          = [local.web_ui_name, "forge-journey-lab"]

  wipe_variables = [
    { name = "ENVIRONMENT", value = local.environment },
    { name = "AWS_REGION", value = data.aws_region.current.region },
    { name = "TABLE", value = aws_dynamodb_table.build_review.name },
    { name = "REPOSITORY", value = aws_ecr_repository.user_applications.name },
    { name = "BUCKET", value = aws_s3_bucket.staging_bucket.id },
    { name = "PROTOTYPE_CLUSTER", value = data.aws_ecs_cluster.prototype_deployment.cluster_name },
    { name = "PROTOTYPE_LOAD_BALANCER", value = data.aws_lb.prototype_deployment.name },
    { name = "UI_CLUSTER", value = local.web_ui_name },
    { name = "UI_SERVICES", value = join(" ", local.wipe_ui_services) },
    { name = "STATE_MACHINE_PREFIX", value = local.application_name },
    { name = "WIPE_STATE_MACHINE_NAME", value = local.wipe_name },
    { name = "DLQ_URL", value = aws_sqs_queue.build_approval_pipe_dlq.url },
    { name = "WIPE_EFS", value = tostring(local.wipe_efs) },
    { name = "EFS_MOUNT", value = local.wipe_efs_mount_path },
  ]
}

resource "terraform_data" "wipe_guard" {
  lifecycle {
    precondition {
      condition     = !local.wipe_keys_set || contains(local.wipe_environments, local.environment)
      error_message = "The environment_wipe_* settings must only be set for ${join(" and ", local.wipe_environments)}, not ${local.environment}. Remove them from application_variables.json."
    }

    precondition {
      condition     = !local.wipe_create || can(regex("^cron\\([^ ()]+( [^ ()]+){5}\\)$", local.wipe_schedule))
      error_message = "environment_wipe_schedule must be an EventBridge cron expression with six fields, e.g. cron(0 2 ? * SUN *)."
    }
  }
}

# ---------- Existing web UI file system ----------

# Looked up rather than read from the web-ui state, which already reads this stack's state.
data "aws_efs_file_system" "plans" {
  count = local.wipe_efs ? 1 : 0

  creation_token = "${local.application_name}-ui-plans"
}

data "aws_security_group" "efs_plans" {
  count = local.wipe_efs ? 1 : 0

  name   = "${local.application_name}-ui-efs"
  vpc_id = data.aws_vpc.vpc.id
}

# ---------- Network ----------

resource "aws_security_group" "wipe_environment" {
  #checkov:skip=CKV2_AWS_5:Attached at runtime by the Step Functions ecs:runTask network configuration, not by a Terraform-managed resource.
  count = local.wipe_create ? 1 : 0

  name        = "${local.wipe_name}-ecs"
  description = "Controls egress for the environment wipe task"
  vpc_id      = data.aws_vpc.vpc.id
  tags        = merge(local.tags, { Name = "${local.wipe_name}-ecs" })
}

resource "aws_vpc_security_group_egress_rule" "wipe_environment_https" {
  count = local.wipe_create ? 1 : 0

  security_group_id = aws_security_group.wipe_environment[0].id
  description       = "HTTPS egress for AWS APIs"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "wipe_environment_efs" {
  count = local.wipe_efs ? 1 : 0

  security_group_id            = aws_security_group.wipe_environment[0].id
  description                  = "NFS to the chat-storage EFS"
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = data.aws_security_group.efs_plans[0].id
}

resource "aws_vpc_security_group_ingress_rule" "efs_from_wipe_environment" {
  count = local.wipe_efs ? 1 : 0

  security_group_id            = data.aws_security_group.efs_plans[0].id
  description                  = "NFS from the environment wipe task"
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.wipe_environment[0].id
}

# ---------- Task role ----------

resource "aws_iam_role" "wipe_environment_task" {
  count = local.wipe_create ? 1 : 0

  name               = "${substr(local.wipe_name, 0, 55)}-task"
  assume_role_policy = data.aws_iam_policy_document.script_runner_ecs_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "wipe_environment_task" {
  statement {
    sid       = "ListAndDescribeTables"
    effect    = "Allow"
    actions   = ["dynamodb:ListTables"]
    resources = ["*"]
  }

  statement {
    sid    = "EmptyTables"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:Scan",
      "dynamodb:BatchWriteItem",
      "dynamodb:DeleteItem",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:dynamodb:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/*"]
  }

  statement {
    sid       = "DeletePrototypeTables"
    effect    = "Allow"
    actions   = ["dynamodb:DeleteTable"]
    resources = [local.prototype_app_table_arn_pattern]
  }

  statement {
    sid       = "ReadRepositoryDetails"
    effect    = "Allow"
    actions   = ["ecr:DescribeRepositories"]
    resources = [aws_ecr_repository.user_applications.arn]
  }

  statement {
    sid       = "EmptyUserApplicationsRepository"
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
    sid       = "DeleteStagingBucketObjects"
    effect    = "Allow"
    actions   = ["s3:DeleteObject", "s3:DeleteObjectVersion"]
    resources = ["${aws_s3_bucket.staging_bucket.arn}/*"]
  }

  statement {
    sid       = "ScaleWebUiServices"
    effect    = "Allow"
    actions   = ["ecs:DescribeServices", "ecs:UpdateService"]
    resources = ["arn:${data.aws_partition.current.partition}:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:service/${local.web_ui_name}/*"]
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

  statement {
    sid       = "ListPrototypeTaskDefinitions"
    effect    = "Allow"
    actions   = ["ecs:ListTaskDefinitionFamilies", "ecs:ListTaskDefinitions"]
    resources = ["*"]
  }

  statement {
    sid    = "DeletePrototypeTaskDefinitions"
    effect = "Allow"
    actions = [
      "ecs:DeregisterTaskDefinition",
      "ecs:DeleteTaskDefinitions",
    ]
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
    sid    = "DeletePrototypeRoutingRules"
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
    sid       = "ListLogGroups"
    effect    = "Allow"
    actions   = ["logs:DescribeLogGroups"]
    resources = ["*"]
  }

  statement {
    sid       = "DeletePrototypeLogGroups"
    effect    = "Allow"
    actions   = ["logs:DeleteLogGroup"]
    resources = ["arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:prototype-*"]
  }

  statement {
    sid       = "ListHostedZones"
    effect    = "Allow"
    actions   = ["route53:ListHostedZones"]
    resources = ["*"]
  }

  statement {
    sid       = "DeletePrototypeDnsRecords"
    effect    = "Allow"
    actions   = ["route53:ListResourceRecordSets", "route53:ChangeResourceRecordSets"]
    resources = [data.aws_route53_zone.prototype_deployment.arn]
  }

  statement {
    sid       = "ListStateMachines"
    effect    = "Allow"
    actions   = ["states:ListStateMachines"]
    resources = ["*"]
  }

  statement {
    sid     = "StopRunningExecutions"
    effect  = "Allow"
    actions = ["states:ListExecutions", "states:StopExecution"]
    resources = [
      "arn:${data.aws_partition.current.partition}:states:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:stateMachine:${local.application_name}-*",
      "arn:${data.aws_partition.current.partition}:states:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:execution:${local.application_name}-*:*",
    ]
  }

  statement {
    sid       = "PurgeApprovalDeadLetterQueue"
    effect    = "Allow"
    actions   = ["sqs:PurgeQueue"]
    resources = [aws_sqs_queue.build_approval_pipe_dlq.arn]
  }
}

resource "aws_iam_role_policy" "wipe_environment_task" {
  count = local.wipe_create ? 1 : 0

  name   = "${local.wipe_name}-task"
  role   = aws_iam_role.wipe_environment_task[0].id
  policy = data.aws_iam_policy_document.wipe_environment_task.json
}

# ---------- Task definition ----------

resource "aws_ecs_task_definition" "wipe_environment" {
  count = local.wipe_create ? 1 : 0

  family                   = local.wipe_task_family
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = local.script_runner_task_cpu
  memory                   = local.script_runner_task_memory
  execution_role_arn       = aws_iam_role.script_runner_ecs_execution.arn
  task_role_arn            = aws_iam_role.wipe_environment_task[0].arn
  tags                     = local.tags

  container_definitions = jsonencode([merge(
    local.script_runner_container_definition,
    local.wipe_efs ? {
      mountPoints = [{
        sourceVolume  = "efs"
        containerPath = local.wipe_efs_mount_path
        readOnly      = false
      }]
    } : {},
  )])

  dynamic "volume" {
    for_each = local.wipe_efs ? [1] : []

    content {
      name = "efs"

      efs_volume_configuration {
        file_system_id     = data.aws_efs_file_system.plans[0].file_system_id
        transit_encryption = "ENABLED"
        root_directory     = "/"
      }
    }
  }

  depends_on = [terraform_data.wipe_guard]
}

# ---------- State machine ----------

module "step_functions_wipe_environment" {
  count  = local.wipe_create ? 1 : 0
  source = "../modules/step_function_builder"

  # A wipe is never retried automatically.
  step_function_retry_attempts = 0
  name                         = local.wipe_name
  execution_role_arn           = aws_iam_role.step_functions_common.arn
  steps = [{
    name            = "wipe_environment"
    type            = "script_runner"
    script_path     = "scripts/maintenance/wipe_environment.py"
    shell_type      = "python3"
    variables       = local.wipe_variables
    timeout_seconds = 10800
  }]
  script_runner = {
    cluster_arn            = aws_ecs_cluster.script_runner.arn
    task_definition_family = local.wipe_task_family
    container_name         = "script-runner"
    subnets                = data.terraform_remote_state.justice_eng_ai.outputs.private_subnet_ids
    security_groups        = [aws_security_group.wipe_environment[0].id]
    assign_public_ip       = "DISABLED"
    execution_role_arn     = aws_iam_role.script_runner_ecs_execution.arn
    task_role_arn          = aws_iam_role.wipe_environment_task[0].arn
    launch_type            = "FARGATE"
  }
  tags = local.tags

  depends_on = [
    aws_iam_role_policy.step_functions_common,
    aws_iam_role_policy.wipe_environment_task,
    aws_ecs_task_definition.wipe_environment,
  ]
}

# ---------- Schedule ----------

resource "aws_iam_role" "wipe_environment_scheduler" {
  count = local.wipe_create ? 1 : 0

  name               = "${local.wipe_name}-scheduler"
  assume_role_policy = data.aws_iam_policy_document.usage_report_scheduler_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "wipe_environment_scheduler" {
  count = local.wipe_create ? 1 : 0

  name = "${local.wipe_name}-start"
  role = aws_iam_role.wipe_environment_scheduler[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "StartEnvironmentWipe"
      Effect   = "Allow"
      Action   = ["states:StartExecution"]
      Resource = [module.step_functions_wipe_environment[0].arn]
    }]
  })
}

resource "aws_scheduler_schedule" "wipe_environment" {
  count = local.wipe_create ? 1 : 0

  name                         = local.wipe_name
  description                  = "Wipes all data from the ${local.environment} environment so it starts clean."
  schedule_expression          = local.wipe_schedule
  schedule_expression_timezone = "Europe/London"
  state                        = local.wipe_enabled ? "ENABLED" : "DISABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = module.step_functions_wipe_environment[0].arn
    role_arn = aws_iam_role.wipe_environment_scheduler[0].arn
    input    = "{}"
  }
}
