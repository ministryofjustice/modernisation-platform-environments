# RDS Enhanced Monitoring
resource "aws_iam_role" "rds-enhanced-monitoring" {
  name               = "${local.application_name_short}-${local.environment}-rds-monitoring"
  assume_role_policy = data.aws_iam_policy_document.rds-enhanced-monitoring-assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "rds-enhanced-monitoring-assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "rds-enhanced-monitoring" {
  role       = aws_iam_role.rds-enhanced-monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ECS Execution Role
resource "aws_iam_role" "execution" {
  name               = "${local.application_name_short}-${local.environment}-execution"
  assume_role_policy = data.aws_iam_policy_document.execution-assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "execution-assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "execution" {
  statement {
    sid    = "AllowECRAuth"
    effect = "Allow"
    actions = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowECRPull"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = [aws_ecr_repository.app.arn]
  }

  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      aws_cloudwatch_log_group.ecs.arn,
      "${aws_cloudwatch_log_group.ecs.arn}:*",
    ]
  }

  statement {
    sid    = "AllowSecretsManagerRead"
    effect = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      "arn:aws:secretsmanager:eu-west-2:${local.environment_management.account_ids["${local.application_name}-${local.environment}"]}:secret:${local.application_name_short}/${local.environment}/*",
    ]
  }

  statement {
    sid    = "AllowKMSDecrypt"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [data.aws_kms_key.general_shared.arn]
  }
}

resource "aws_iam_role_policy" "execution" {
  name   = "${local.application_name_short}-${local.environment}-execution"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution.json
}

# ECS Task Role
resource "aws_iam_role" "task" {
  name               = "${local.application_name_short}-${local.environment}-task"
  assume_role_policy = data.aws_iam_policy_document.task-assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "task-assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "task" {
  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
    ]
    resources = ["arn:aws:logs:eu-west-2:${local.environment_management.account_ids["${local.application_name}-${local.environment}"]}:*"]
  }

  statement {
    sid    = "AllowSSMExecCommand"
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowS3FilesyncBucket"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      module.s3-bucket-files.bucket.arn,
      "${module.s3-bucket-files.bucket.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "task" {
  name   = "${local.application_name_short}-${local.environment}-task"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task.json
}

# RabbitMQ EC2 Instance Role
resource "aws_iam_role" "rabbitmq" {
  name               = "${local.application_name_short}-${local.environment}-rabbitmq"
  assume_role_policy = data.aws_iam_policy_document.rabbitmq-assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "rabbitmq-assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Allows SSM Session Manager access
resource "aws_iam_role_policy_attachment" "rabbitmq-ssm" {
  role       = aws_iam_role.rabbitmq.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "rabbitmq" {
  # Allows user_data to fetch the RabbitMQ password from Secrets Manager on first boot
  statement {
    sid     = "AllowSecretsManagerRead"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.rabbitmq-password.arn]
  }

  statement {
    sid    = "AllowKMSDecrypt"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [data.aws_kms_key.general_shared.arn]
  }
}

resource "aws_iam_role_policy" "rabbitmq" {
  name   = "${local.application_name_short}-${local.environment}-rabbitmq"
  role   = aws_iam_role.rabbitmq.id
  policy = data.aws_iam_policy_document.rabbitmq.json
}

resource "aws_iam_instance_profile" "rabbitmq" {
  name = "${local.application_name_short}-${local.environment}-rabbitmq"
  role = aws_iam_role.rabbitmq.name
  tags = local.tags
}

# GitHub Actions OIDC Role
# Allows GitHub Actions workflows in the CFO-DataManagementSystem repository to deploy
# MP OIDC Module - https://github.com/ministryofjustice/modernisation-platform-github-oidc-role
module "github-actions-oidc-role" {
  source = "github.com/ministryofjustice/modernisation-platform-github-oidc-role?ref=b40748ec162b446f8f8d282f767a85b6501fd192" # v4.0.0

  github_repositories = ["ministryofjustice/CFO-DataManagementSystem"]
  role_name           = "${local.application_name_short}-${local.environment}-github-actions"
  policy_jsons        = [data.aws_iam_policy_document.github-actions.json]
  subject_claim       = "repo:ministryofjustice/CFO-DataManagementSystem:environment:${local.environment}"
  tags                = local.tags
}

data "aws_iam_policy_document" "github-actions" {
  # ECR authentication (account-wide, required for GetAuthorizationToken)
  statement {
    sid     = "AllowECRAuth"
    effect  = "Allow"
    actions = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # ECR image push for the app repository
  statement {
    sid    = "AllowECRPush"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
    resources = [aws_ecr_repository.app.arn]
  }

  # KMS decrypt for ECR repository encryption
  statement {
    sid    = "AllowECRKMSDecrypt"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [aws_kms_key.ecr.arn]
  }

  # ECS task definition registration (required to deploy new image versions)
  statement {
    sid    = "AllowECSTaskDefinition"
    effect = "Allow"
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:DescribeTaskDefinition",
      "ecs:ListTaskDefinitions",
    ]
    resources = ["*"]
  }

  # ECS service updates (scoped to this environment's cluster)
  statement {
    sid    = "AllowECSServiceUpdate"
    effect = "Allow"
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices",
    ]
    resources = [
      "arn:aws:ecs:eu-west-2:${local.environment_management.account_ids["${local.application_name}-${local.environment}"]}:service/${local.application_name_short}-${local.environment}-cluster/*"
    ]
  }

  # IAM PassRole — allows GitHub Actions to assign task/execution roles to ECS task definitions
  statement {
    sid    = "AllowIAMPassRole"
    effect = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.task.arn,
      aws_iam_role.execution.arn,
    ]
  }

  # Read app secrets from Secrets Manager
  statement {
    sid     = "AllowSecretsManagerRead"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      "arn:aws:secretsmanager:eu-west-2:${local.environment_management.account_ids["${local.application_name}-${local.environment}"]}:secret:${local.application_name_short}/${local.environment}/*",
    ]
  }

  statement {
    sid    = "AllowKMSDecrypt"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [data.aws_kms_key.general_shared.arn]
  }
}