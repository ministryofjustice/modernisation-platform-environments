# This template creates the ECS infrastructure required to host the script runner container.

locals {
  script_runner_task_definition_family = "${local.application_name}-script-runner"
  script_runner_ecr_repository_name    = "modernisation-platform-ai-builder-core"
  script_runner_ecr_repository_url     = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.${data.aws_region.current.region}.${data.aws_partition.current.dns_suffix}/${local.script_runner_ecr_repository_name}"
  # The workflow stores the full prefixed tag; normalize the bootstrap SHA too.
  script_runner_image_tag = format(
    "%s%s",
    "script-runner-",
    trimprefix(data.aws_ssm_parameter.script_runner_container_image_tag.value, "script-runner-")
  )

  # IAM role names are capped at 64 characters, so the script runner roles use an
  # abbreviated, length-bounded prefix rather than the full application name.
  script_runner_role_name_prefix = substr("${local.application_name}-script-runner", 0, 47)

  script_runner_environment_variables = []

  # Fargate task capacity; adjust after the script requirements are known.
  script_runner_task_cpu    = 1024
  script_runner_task_memory = 2048
}

data "aws_partition" "current" {}

resource "aws_cloudwatch_log_group" "script_runner" {
  # checkov:skip=CKV_AWS_158:Encrypted at rest with the AWS-managed CloudWatch
  # Logs KMS key -- consistent with the UI task's log group (see ecs.tf).
  # checkov:skip=CKV_AWS_338:30-day retention is deliberate for a prototype;
  # logs are for short-term operational debugging of script runner stages.
  name              = "/ecs/${local.application_name}-script-runner"
  retention_in_days = 30
  tags              = local.tags
}

resource "aws_ecs_cluster" "script_runner" {
  name = "${local.application_name}-script-runner"
  tags = local.tags

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Egress-only security group: script runner tasks never accept inbound traffic,
# they only call out to AWS APIs used by the configured scripts.
resource "aws_security_group" "script_runner_task" {
  #checkov:skip=CKV2_AWS_5:Attached at runtime by the Step Functions ecs:runTask network configuration, not by a Terraform-managed resource.
  name        = "${local.application_name}-script-runner-ecs"
  description = "Controls egress for AI prototype script runner ECS/Fargate tasks"
  vpc_id      = data.terraform_remote_state.justice_eng_ai.outputs.vpc_id
  tags        = merge(local.tags, { Name = "${local.application_name}-script-runner-ecs" })
}

resource "aws_vpc_security_group_egress_rule" "script_runner_task_https" {
  security_group_id = aws_security_group.script_runner_task.id
  description       = "HTTPS egress for AWS APIs"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

data "aws_iam_policy_document" "script_runner_ecs_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ---------- Execution role: pulls the image and writes container logs ----------

resource "aws_iam_role" "script_runner_ecs_execution" {
  name               = "${local.script_runner_role_name_prefix}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.script_runner_ecs_assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "script_runner_ecs_execution" {
  role       = aws_iam_role.script_runner_ecs_execution.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# The task role provides AWS credentials to code running inside the container.
# Script permissions are defined in the policy document below and attached as
# a separate managed policy. Keep image-pull and log-write permissions on the
# execution role above.
resource "aws_iam_role" "script_runner_ecs_task" {
  name               = "${local.script_runner_role_name_prefix}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.script_runner_ecs_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "script_runner_ecs_task" {
  source_policy_documents = [data.aws_iam_policy_document.script_runner_common.json]

  statement {
    sid       = "ListBucketsOwnedByCurrentAccount"
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }

  statement {
    sid       = "ManageBucketsInCurrentAccount"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["arn:${data.aws_partition.current.partition}:s3:::*", "arn:${data.aws_partition.current.partition}:s3:::*/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:ResourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "ManageEcsClustersInCurrentAccount"
    effect = "Allow"
    actions = [
      "ecs:CreateCluster",
      "ecs:DeleteCluster",
      "ecs:DescribeClusters",
      "ecs:TagResource",
      "ecs:UntagResource",
      "ecs:UpdateCluster",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:ecs:*:${data.aws_caller_identity.current.account_id}:cluster/*"]
  }

  statement {
    sid       = "ListEcsClusters"
    effect    = "Allow"
    actions   = ["ecs:ListClusters"]
    resources = ["*"]
  }

  # RunInstances authorizes several resource types; scope each created or
  # selected resource to this account rather than granting ec2:* on "*".
  statement {
    sid    = "LaunchEc2InstancesInCurrentAccount"
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*",
      "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:image/*",
      "arn:${data.aws_partition.current.partition}:ec2:*::image/*",
      "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:volume/*",
      "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:network-interface/*",
      "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:security-group/*",
      "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:subnet/*",
      "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:key-pair/*",
      "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:launch-template/*",
      "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:placement-group/*",
      "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:snapshot/*",
    ]
  }

  statement {
    sid    = "ManageEc2InstancesAndEbsVolumesInCurrentAccount"
    effect = "Allow"
    actions = [
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:TerminateInstances",
      "ec2:ModifyInstanceAttribute",
      "ec2:CreateVolume",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
      "ec2:ModifyVolume",
      "ec2:DeleteVolume",
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*",
      "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:volume/*",
    ]
  }

  statement {
    sid    = "DescribeEc2Resources"
    effect = "Allow"
    actions = [
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeKeyPairs",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSnapshots",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVpcs",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ManageCloudWatchLogGroupsInCurrentAccount"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:PutRetentionPolicy",
      "logs:DeleteRetentionPolicy",
      "logs:TagResource",
      "logs:UntagResource",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:ListTagsForResource",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:logs:*:${data.aws_caller_identity.current.account_id}:log-group:*",
      "arn:${data.aws_partition.current.partition}:logs:*:${data.aws_caller_identity.current.account_id}:log-group:*:*",
    ]
  }

  statement {
    sid       = "DescribeCloudWatchLogGroups"
    effect    = "Allow"
    actions   = ["logs:DescribeLogGroups"]
    resources = ["*"]
  }

  statement {
    sid    = "ManageAlbListenerRulesAndTargetGroupsInCurrentAccount"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:targetgroup/*/*",
      "arn:${data.aws_partition.current.partition}:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener-rule/app/*/*/*",
      "arn:${data.aws_partition.current.partition}:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener/app/*/*/*",
    ]
  }

  statement {
    sid    = "DescribeAlbResources"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "script_runner_ecs_task" {
  name        = "${local.application_name}-script-runner-task"
  description = "Permissions for script-runner tasks to manage configured resources in this account."
  policy      = data.aws_iam_policy_document.script_runner_ecs_task.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "script_runner_ecs_task" {
  role       = aws_iam_role.script_runner_ecs_task.name
  policy_arn = aws_iam_policy.script_runner_ecs_task.arn
}

resource "aws_ecs_task_definition" "script_runner" {
  family                   = local.script_runner_task_definition_family
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = local.script_runner_task_cpu
  memory                   = local.script_runner_task_memory
  execution_role_arn       = aws_iam_role.script_runner_ecs_execution.arn
  task_role_arn            = aws_iam_role.script_runner_ecs_task.arn
  tags                     = local.tags

  container_definitions = jsonencode([
    {
      name      = "script-runner"
      image     = "${local.script_runner_ecr_repository_url}:${local.script_runner_image_tag}"
      essential = true

      environment = local.script_runner_environment_variables

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.script_runner.name
          awslogs-region        = data.aws_region.current.region
          awslogs-stream-prefix = "script-runner"
          mode                  = "blocking"
        }
      }
    }
  ])
}