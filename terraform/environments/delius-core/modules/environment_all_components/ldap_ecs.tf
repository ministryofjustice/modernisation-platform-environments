module "ldap_ecs_policies" {
  source       = "../ecs_policies"
  env_name     = var.env_name
  service_name = "openldap"
  tags         = local.tags
  extra_exec_role_allow_statements = [
    "elasticfilesystem:ClientRootAccess",
    "elasticfilesystem:ClientWrite",
    "elasticfilesystem:ClientMount",
    "s3:GetObject",
    "s3:ListBucket",
    "s3:HeadBucket"
  ]
}

# Create s3 bucket for deployment state
module "s3_bucket_ldap_deployment" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.0.0"

  providers = {
    aws.bucket-replication = aws.bucket-replication
  }
  bucket_prefix      = "${var.env_name}-ldap-deployment-"
  versioning_enabled = true

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = local.tags
}

resource "aws_security_group" "ldap" {
  name        = "${var.env_name}-ldap-sg"
  description = "Security group for the ${var.env_name} ldap service"
  vpc_id      = var.account_info.vpc_id
  tags        = local.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_all_egress" {
  description       = "Allow all outbound traffic to any IPv4 address"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ldap.id
}

resource "aws_security_group_rule" "ldap_nlb" {
  description       = "Allow inbound traffic from VPC"
  type              = "ingress"
  from_port         = local.ldap_port
  to_port           = local.ldap_port
  protocol          = "TCP"
  security_group_id = aws_security_group.ldap.id
  cidr_blocks       = [var.account_config.shared_vpc_cidr]
}

resource "aws_security_group_rule" "allow_ldap_from_legacy_env" {
  description       = "Allow inbound LDAP traffic from corresponding legacy VPC"
  type              = "ingress"
  from_port         = local.ldap_port
  to_port           = local.ldap_port
  protocol          = "TCP"
  security_group_id = aws_security_group.ldap.id
  cidr_blocks       = [var.environment_config.migration_environment_vpc_cidr]
}

resource "aws_security_group_rule" "efs_ingress_ldap" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ldap_efs.id
  security_group_id        = aws_security_group.ldap.id
}

resource "aws_cloudwatch_log_group" "ldap" {
  name              = "${var.env_name}-ldap-ecs"
  retention_in_days = 30
}

output "s3_bucket_ldap_deployment_name" {
  value = module.s3_bucket_ldap_deployment.bucket.id
}

data "aws_iam_policy_document" "ecs_task" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ldap_ecs_task" {
  name               = "${var.env_name}-ldap-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task.json
  tags               = local.tags
}

data "aws_iam_policy_document" "ecs_service" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ldap_ecs_service" {
  name               = "${var.env_name}-ldap-service"
  assume_role_policy = data.aws_iam_policy_document.ecs_service.json
  tags               = local.tags
}

data "aws_iam_policy_document" "ecs_service_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "ec2:Describe*",
      "ec2:AuthorizeSecurityGroupIngress",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets"
    ]
  }
}

resource "aws_iam_role_policy" "ldap_ecs_service" {
  name   = "${var.env_name}-ldap-service"
  policy = data.aws_iam_policy_document.ecs_service_policy.json
  role   = aws_iam_role.ldap_ecs_service.id
}

data "aws_iam_policy_document" "ecs_ssm_exec" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
  }
}

data "aws_iam_policy_document" "ecs_s3" {
  statement {
    effect    = "Allow"
    resources = [module.s3_bucket_migration.bucket.arn]

    actions = [
      "s3:*"
    ]
  }
}

resource "aws_iam_role_policy" "ldap_ecs_s3" {
  name   = "${var.env_name}-ldap-service-s3"
  policy = data.aws_iam_policy_document.ecs_s3.json
  role   = aws_iam_role.ldap_ecs_task.id
}

resource "aws_iam_role_policy" "ecs_ssm_exec" {
  name   = "${var.env_name}-ldap-service-ssm-exec"
  policy = data.aws_iam_policy_document.ecs_ssm_exec.json
  role   = aws_iam_role.ldap_ecs_task.id
}

# IAM role that the Amazon ECS container agent and the Docker daemon can assume
data "aws_iam_policy_document" "ecs_task_exec" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ldap_ecs_exec" {
  name               = "${var.env_name}-ldap-task-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_exec.json
  tags               = local.tags
}

data "aws_iam_policy_document" "ecs_exec" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ssm:GetParameters",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "secretsmanager:GetSecretValue"
    ]
  }
}

resource "aws_iam_role_policy" "ecs_exec" {
  name   = "${var.env_name}-ldap-task-exec"
  policy = data.aws_iam_policy_document.ecs_exec.json
  role   = aws_iam_role.ldap_ecs_exec.id
}

# temp log group for testing ldap
resource "aws_cloudwatch_log_group" "ldap_test" {
  name              = "/ecs/ldap_${var.env_name}"
  retention_in_days = 7
}
