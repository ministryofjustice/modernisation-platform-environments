resource "aws_iam_role" "eventbridge_invoke_lambda" {
  count              = local.enable_aws_health_lambda ? 1 : 0
  name               = "EventBridgeInvokeAWSHealthLambda"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_assume_role.json
}

resource "aws_iam_role_policy" "invoke_aws_health_lambda" {
  count  = local.enable_aws_health_lambda ? 1 : 0
  name   = "InvokeAWSHealthLambda"
  role   = aws_iam_role.eventbridge_invoke_lambda[count.index].id
  policy = data.aws_iam_policy_document.invoke_aws_health_lambda[count.index].json
}