data "aws_iam_policy_document" "assume_lambda" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "health_signals_lambda" {
  name               = "${var.name_prefix}-health-signals-lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
}

data "aws_iam_policy_document" "health_signals_lambda_policy" {
  # publish Custom/Health metrics in this OP account
  statement {
    sid     = "PutHealthMetrics"
    effect  = "Allow"
    actions = ["cloudwatch:PutMetricData"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = [var.health_namespace]
    }
  }

  # assume tenant reader roles
  statement {
    sid     = "AssumeTenantRoles"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [
      for t in var.tenants : "arn:aws:iam::${t.account_id}:role/${var.tenant_role_name}"
    ]
  }

  # logs
  statement {
    sid     = "Logs"
    effect  = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "health_signals_lambda_policy" {
  name   = "${var.name_prefix}-health-signals-lambda"
  role   = aws_iam_role.health_signals_lambda.id
  policy = data.aws_iam_policy_document.health_signals_lambda_policy.json
}

output "health_signals_lambda_role_arn" {
  value = aws_iam_role.health_signals_lambda.arn
}
