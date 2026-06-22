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