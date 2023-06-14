data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "lambda_execution" {
  statement {
    resources = [
      "arn:aws:logs:${var.region}:${var.account}:log-group:/aws/lambda/${var.name}-function*"
    ]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }

  statement {
    resources = ["*"]

    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
    ]
  }

  statement {
    resources = ["*"]

    actions = [
      "cloudwatch:PutMetricData"
    ]
  }

  statement {
    resources = ["*"]

    actions = [
      "cloudwatch:PutMetricData"
    ]
  }
}

resource "aws_iam_policy" "lambda_execution" {
  count  = var.enable_lambda ? 1 : 0

  name   = "${var.name}-policy"
  policy = data.aws_iam_policy_document.lambda_execution.json
}

resource "aws_iam_role" "this" {
  count               = var.enable_lambda ? 1 : 0

  name                = "${var.name}-role"
  assume_role_policy  = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_execution" {
  count      = var.enable_lambda ? 1 : 0

  role       = aws_iam_role.this[0].id
  policy_arn = aws_iam_policy.lambda_execution[0].arn
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = var.enable_lambda ? toset(var.policies): toset([])

  role       = aws_iam_role.this[0].id
  policy_arn = each.value
}