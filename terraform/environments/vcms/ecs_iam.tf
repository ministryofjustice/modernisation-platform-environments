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

resource "aws_iam_role" "service" {
  name               = "vcms-${local.environment}-ecs-service"
  assume_role_policy = data.aws_iam_policy_document.ecs_service.json
  tags               = local.tags
}

data "aws_iam_policy_document" "service_policy" {
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

resource "aws_iam_role_policy" "service_policy" {
  name   = "vcms-${local.environment}-service"
  policy = data.aws_iam_policy_document.service_policy.json
  role   = aws_iam_role.service.id
}

data "aws_iam_policy_document" "ecs_task_exec" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "task_exec" {
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
      "secretsmanager:GetSecretValue",
      "kms:Decrypt",
    ]
  }
}

resource "aws_iam_role_policy" "task_exec" {
  name   = "vcms-${local.environment}-task-exec"
  policy = data.aws_iam_policy_document.task_exec.json
  role   = aws_iam_role.task_exec.id
}


resource "aws_iam_role" "task_exec" {
  name               = "vcms-${local.environment}-ecs-task-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_exec.json
  tags               = local.tags
}


resource "aws_iam_role" "task" {
  name               = "vcms-${local.environment}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.task_trust.json
  tags               = local.tags
}

data "aws_iam_policy_document" "task_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "task" {
  # S3 permissions for report uploads
  statement {
    sid    = "AllowS3ReportUpload"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:ListBucket"
    ]
    resources = [
      "${module.vcms_testing_reports_bucket.bucket.arn}",
      "${module.vcms_testing_reports_bucket.bucket.arn}/*"
    ]
  }

  # S3 permissions for vcms bucket
  statement {
    sid    = "AllowVCMSBucket"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      "${module.vcms_bucket.bucket.arn}",
      "${module.vcms_bucket.bucket.arn}/*"
    ]
  }


  # ecs exec
  statement {
    sid    = "AllowSSMExec"
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }

  # kms for encrypted S3
  statement {
    sid    = "AllowKMSUsage"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      local.account_config.kms_keys.general_shared
    ]
  }
}

resource "aws_iam_role_policy" "task" {
  name   = "vcms-${local.environment}-task"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task.json
}