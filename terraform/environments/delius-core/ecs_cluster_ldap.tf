module "ecs" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=v1.0.0"

  environment = local.environment
  name        = format("%s-openldap", local.application_name)

  tags = local.tags
}

# Create s3 bucket for deployment state
module "s3_bucket_app_deployment" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.4.0"

  providers = {
    aws.bucket-replication = aws
  }
  bucket_name        = "${local.application_name}-${local.environment}-openldap-deployment"
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
  vpc_id      = data.aws_vpc.shared.id
  name        = format("hmpps-%s-%s-ldap-service", local.environment, local.application_name)
  description = "Security group for the ${local.application_name} openldap service"
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
  description              = "Allow inbound traffic from NLB"
  type                     = "ingress"
  from_port                = local.openldap_port
  to_port                  = local.openldap_port
  protocol                 = "TCP" 
  security_group_id        = aws_security_group.ldap.id
  cidr_blocks = ["0.0.0.0/0"]
 }

resource "aws_cloudwatch_log_group" "openldap" {
  name              = format("%s-openldap-ecs", local.application_name)
  retention_in_days = 30
}

output "s3_bucket_app_deployment_name" {s
  value = module.s3_bucket_app_deployment.bucket.id
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

resource "aws_iam_role" "ecs_task" {
  name               = format("hmpps-%s-%s-openldap-task", local.environment, local.application_name)
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

resource "aws_iam_role" "ecs_service" {
  name               = format("hmpps-%s-%s-openldap-service", local.environment, local.application_name)
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

resource "aws_iam_role_policy" "ecs_service" {
  name   = format("hmpps-%s-%s-openldap-service", local.environment, local.application_name)
  policy = data.aws_iam_policy_document.ecs_service_policy.json
  role   = aws_iam_role.ecs_service.id
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

resource "aws_iam_role_policy" "ecs_ssm_exec" {
  name   = format("hmpps-%s-%s-openldap-service-ssm-exec", local.environment, local.application_name)
  policy = data.aws_iam_policy_document.ecs_ssm_exec.json
  role   = aws_iam_role.ecs_task.id
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

resource "aws_iam_role" "ecs_exec" {
  name               = format("hmpps-%s-%s-openldap-task-exec", local.environment, local.application_name)
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
  name   = format("hmpps-%s-%s-openldap-task-exec", local.environment, local.application_name)
  policy = data.aws_iam_policy_document.ecs_exec.json
  role   = aws_iam_role.ecs_exec.id
}
