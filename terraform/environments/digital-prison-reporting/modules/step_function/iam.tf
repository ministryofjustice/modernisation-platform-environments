data "aws_iam_policy_document" "step_function_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "states.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "step_function_execution" {
  statement {
    resources = [
      "*"
    ]

    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups"
    ]
  }

  statement {
    resources = ["*"]

    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets"
    ]
  }
}

resource "aws_iam_policy" "step_function_execution" {
  count = var.enable_step_function ? 1 : 0

  name   = "${var.step_function_name}-policy"
  policy = data.aws_iam_policy_document.step_function_execution.json
}

resource "aws_iam_role" "step_function_role" {
  count = var.enable_step_function ? 1 : 0

  name               = "${var.step_function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.step_function_role.json
}

resource "aws_iam_role_policy_attachment" "step_function_role_policy_attachment" {
  for_each = var.enable_step_function ? toset(var.additional_policies) : toset([])

  role       = aws_iam_role.step_function_role[0].id
  policy_arn = each.value
}