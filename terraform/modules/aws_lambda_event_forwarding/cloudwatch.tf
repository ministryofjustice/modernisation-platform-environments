resource "aws_cloudwatch_event_rule" "aws_health_event_rule" {
  count          = local.enable_aws_health_lambda ? 1 : 0
  name           = var.aws_health_lambda_configuration.rule_name
  event_bus_name = "default"
  event_pattern = jsonencode({
    source = ["aws.health"]
  })
}

resource "aws_cloudwatch_event_target" "aws_health_event_target" {
  count          = local.enable_aws_health_lambda ? 1 : 0
  rule           = aws_cloudwatch_event_rule.aws_health_event_rule[count.index].name
  event_bus_name = "default"
  target_id      = "AWSHealthLambda"
  role_arn       = aws_iam_role.eventbridge_invoke_lambda[count.index].arn
  arn            = var.aws_health_lambda_configuration.aws_health_lambda_arn
}

resource "aws_cloudwatch_event_rule" "aws_securityhub_event_rule" {
  count          = local.enable_aws_securityhub_lambda ? 1 : 0
  name           = var.aws_securityhub_lambda_configuration.rule_name
  event_bus_name = "default"
  event_pattern = jsonencode({
    source        = ["aws.securityhub"]
    "detail-type" = ["Security Hub Findings - Imported"]
  })
}

resource "aws_cloudwatch_event_target" "aws_securityhub_event_target" {
  count          = local.enable_aws_securityhub_lambda ? 1 : 0
  rule           = aws_cloudwatch_event_rule.aws_securityhub_event_rule[count.index].name
  event_bus_name = "default"
  target_id      = "AWSSecurityHubLambda"
  role_arn       = aws_iam_role.eventbridge_invoke_securityhub_lambda[count.index].arn
  arn            = var.aws_securityhub_lambda_configuration.aws_securityhub_lambda_arn
}
