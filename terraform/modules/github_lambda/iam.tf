data "aws_iam_policy_document" "eventbridge_scheduler_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "eventbridge_scheduler_lambda" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
    ]
    resources = [aws_lambda_function.github_workflow_trigger.arn]
  }
}

data "aws_iam_policy_document" "lambda_kms" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
    ]
    resources = [aws_kms_key.lambda.arn]
  }
}

data "aws_iam_policy_document" "lambda_web_identity" {
  statement {
    effect = "Allow"
    actions = [
      "sts:GetWebIdentityToken",
    ]
    resources = ["*"]

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "sts:IdentityTokenAudience"
      values   = [var.web_identity_audience]
    }

    condition {
      test     = "NumericLessThanEquals"
      variable = "sts:DurationSeconds"
      values   = [var.web_identity_duration_seconds]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:SigningAlgorithm"
      values   = [var.web_identity_signing_algorithm]
    }
  }
}

data "aws_iam_policy_document" "scheduler_kms" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
    ]
    resources = [aws_kms_key.scheduler.arn]
  }
}

resource "aws_iam_role" "eventbridge_scheduler" {
  name               = "${var.project_name}-eventbridge-scheduler"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_scheduler_assume_role.json
}

resource "aws_iam_role" "lambda" {
  name               = "${var.project_name}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "eventbridge_scheduler_lambda" {
  name   = "${var.project_name}-invoke-lambda"
  policy = data.aws_iam_policy_document.eventbridge_scheduler_lambda.json
  role   = aws_iam_role.eventbridge_scheduler.id
}

resource "aws_iam_role_policy" "lambda_kms" {
  name   = "${var.project_name}-lambda-kms"
  policy = data.aws_iam_policy_document.lambda_kms.json
  role   = aws_iam_role.lambda.id
}

resource "aws_iam_role_policy" "lambda_web_identity" {
  name   = "${var.project_name}-web-identity"
  policy = data.aws_iam_policy_document.lambda_web_identity.json
  role   = aws_iam_role.lambda.id
}

resource "aws_iam_role_policy" "scheduler_kms" {
  name   = "${var.project_name}-scheduler-kms"
  policy = data.aws_iam_policy_document.scheduler_kms.json
  role   = aws_iam_role.eventbridge_scheduler.id
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda.name
}
