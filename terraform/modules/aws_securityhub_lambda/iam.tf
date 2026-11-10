data "aws_iam_policy_document" "securityhub_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "securityhub_dlq" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
    ]
    resources = [aws_sqs_queue.securityhub_findings_dlq.arn]
  }
}

data "aws_iam_policy_document" "securityhub_kms" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
    ]
    resources = [aws_kms_key.securityhub.arn]
  }
}

data "aws_iam_policy_document" "securityhub_kms_key_policy" {
  statement {
    sid    = "AllowRootAccountKeyAdministration"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["arn:aws:kms:${var.aws_region}:${var.aws_account_id}:key/*"]

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [var.aws_account_id]
    }
  }

  statement {
    sid    = "AllowLambdaExecutionRoleToUseKey"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.securityhub.arn]
    }
    actions   = ["kms:*"]
    resources = [aws_kms_key.securityhub.arn]
  }
}

data "aws_iam_policy_document" "securityhub_web_identity" {
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

resource "aws_iam_role" "securityhub" {
  name               = "${var.project_name}-lambda"
  assume_role_policy = data.aws_iam_policy_document.securityhub_assume_role.json
}

resource "aws_iam_role_policy" "securityhub_kms" {
  name   = "${var.project_name}-securityhub-lambda-kms"
  policy = data.aws_iam_policy_document.securityhub_kms.json
  role   = aws_iam_role.securityhub.id
}

resource "aws_iam_role_policy" "securityhub_dlq" {
  name   = "${var.project_name}-securityhub-lambda-dlq"
  policy = data.aws_iam_policy_document.securityhub_dlq.json
  role   = aws_iam_role.securityhub.id
}

resource "aws_iam_role_policy" "securityhub_web_identity" {
  name   = "${var.project_name}-securityhub-web-identity"
  policy = data.aws_iam_policy_document.securityhub_web_identity.json
  role   = aws_iam_role.securityhub.id
}

resource "aws_iam_role_policy_attachment" "securityhub_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.securityhub.name
}
