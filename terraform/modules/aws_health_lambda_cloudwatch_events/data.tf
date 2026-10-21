data "aws_iam_policy_document" "eventbridge_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "invoke_aws_health_lambda" {
  count = local.enable_aws_health_lambda ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]
    resources = [
      var.aws_health_lambda_configuration.aws_health_lambda_arn
    ]
  }
}
