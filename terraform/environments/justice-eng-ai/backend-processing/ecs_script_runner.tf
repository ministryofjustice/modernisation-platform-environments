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

  # Task capacity; adjust after the script requirements are known.
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

# ---------- EC2 capacity: gives the task access to a Docker daemon ----------
# Fargate cannot run docker, and the prototype image build needs docker/buildx,
# so the script runner tasks run on a single ECS-optimised EC2 instance and
# use its Docker daemon via the mounted socket.

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

data "aws_iam_policy_document" "script_runner_ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "script_runner_ec2_instance" {
  name               = "${local.script_runner_role_name_prefix}-ec2-instance"
  assume_role_policy = data.aws_iam_policy_document.script_runner_ec2_assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "script_runner_ec2_instance" {
  for_each = toset([
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ])

  role       = aws_iam_role.script_runner_ec2_instance.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "script_runner_ec2_instance" {
  name = "${local.script_runner_role_name_prefix}-ec2-instance"
  role = aws_iam_role.script_runner_ec2_instance.name
  tags = local.tags
}

resource "aws_launch_template" "script_runner" {
  name_prefix            = "${local.application_name}-script-runner-"
  image_id               = data.aws_ssm_parameter.ecs_optimized_ami.value
  instance_type          = "t3.large"
  vpc_security_group_ids = [aws_security_group.script_runner_task.id]
  user_data              = base64encode("#!/bin/bash\necho ECS_CLUSTER=${aws_ecs_cluster.script_runner.name} >> /etc/ecs/ecs.config\n")
  tags                   = local.tags

  iam_instance_profile {
    arn = aws_iam_instance_profile.script_runner_ec2_instance.arn
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 50
      volume_type = "gp3"
      encrypted   = true
      kms_key_id  = aws_kms_key.script_runner_ebs.arn
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.tags, { Name = "${local.application_name}-script-runner" })
  }
}

resource "aws_autoscaling_group" "script_runner" {
  name                    = "${local.application_name}-script-runner"
  min_size                = 1
  max_size                = 1
  desired_capacity        = 1
  vpc_zone_identifier     = data.terraform_remote_state.justice_eng_ai.outputs.private_subnet_ids
  service_linked_role_arn = data.aws_iam_role.script_runner_autoscaling.arn

  launch_template {
    id      = aws_launch_template.script_runner.id
    version = aws_launch_template.script_runner.latest_version
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 0
    }
  }

  dynamic "tag" {
    for_each = merge(local.tags, { Name = "${local.application_name}-script-runner" })

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_ecs_task_definition" "script_runner" {
  family                   = local.script_runner_task_definition_family
  requires_compatibilities = ["EC2"]
  # Host networking so the build script can reach containers it publishes on
  # the instance's Docker daemon (the image smoke test hits 127.0.0.1).
  network_mode       = "host"
  cpu                = local.script_runner_task_cpu
  memory             = local.script_runner_task_memory
  execution_role_arn = aws_iam_role.script_runner_ecs_execution.arn
  task_role_arn      = aws_iam_role.script_runner_ecs_task.arn
  tags               = local.tags

  volume {
    name      = "docker-socket"
    host_path = "/var/run/docker.sock"
  }

  container_definitions = jsonencode([
    {
      name      = "script-runner"
      image     = "${local.script_runner_ecr_repository_url}:${local.script_runner_image_tag}"
      essential = true
      # The docker socket is root-owned; the image's default user cannot use it.
      user = "root"

      environment = local.script_runner_environment_variables

      mountPoints = [
        {
          sourceVolume  = "docker-socket"
          containerPath = "/var/run/docker.sock"
          readOnly      = false
        }
      ]

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

data "aws_iam_role" "script_runner_autoscaling" {
  name = "AWSServiceRoleForAutoScaling"
}

data "aws_iam_policy_document" "script_runner_ebs" {
  statement {
    sid       = "EnableAccountIAMPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid    = "AllowAutoScalingKeyUse"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.script_runner_autoscaling.arn]
    }
  }

  statement {
    sid       = "AllowAutoScalingResourceGrants"
    effect    = "Allow"
    actions   = ["kms:CreateGrant"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.script_runner_autoscaling.arn]
    }

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

resource "aws_kms_key" "script_runner_ebs" {
  description             = "Encrypt EBS volumes for the script runner EC2 instances"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.script_runner_ebs.json
  tags                    = local.tags
}

resource "aws_kms_alias" "script_runner_ebs" {
  name          = "alias/${local.application_name}-script-runner-ebs"
  target_key_id = aws_kms_key.script_runner_ebs.key_id
}
