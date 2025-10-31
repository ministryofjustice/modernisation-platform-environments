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


data "aws_iam_policy_document" "lambda_execution_policy" {
  #checkov:skip=CKV_AWS_356: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions. TO DO Will be addressed as part of https://dsdmoj.atlassian.net/browse/DPR2-1083"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  statement {
    resources = [
      "arn:aws:logs:eu-west-2:*:*"
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
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeInstances",
      "ec2:AttachNetworkInterface"
    ]
  }
}

resource "aws_iam_policy" "lambda_execution_policy" {
  count = var.enable_lambda ? 1 : 0

  name   = "${var.name}-policy"
  policy = data.aws_iam_policy_document.lambda_execution_policy.json
}


resource "aws_iam_role" "lambda_execution_role" {
  count = var.enable_lambda ? 1 : 0

  name               = "${var.name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_execution" {
  count = var.enable_lambda ? 1 : 0

  role       = aws_iam_role.lambda_execution_role[0].id
  policy_arn = aws_iam_policy.lambda_execution_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = var.enable_lambda ? toset(var.policies) : toset([])

  role       = aws_iam_role.lambda_execution_role[0].id
  policy_arn = each.value
}
