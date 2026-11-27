resource "aws_cloudwatch_event_rule" "events_to_kafka" {
  count          = contains(local.deploy_to, local.environment) ? 1 : 0
  name           = "${local.name}-events-to-kafka"
  description    = "Send every event on the Integration Hub events bus to Kafka"
  event_bus_name = data.aws_cloudwatch_event_bus.events.name

  event_pattern = jsonencode({
    account = [data.aws_caller_identity.current.account_id]
  })

  tags = local.extended_tags
}

resource "aws_cloudwatch_event_target" "events_to_kafka" {
  count          = contains(local.deploy_to, local.environment) ? 1 : 0
  rule           = aws_cloudwatch_event_rule.events_to_kafka[0].name
  event_bus_name = data.aws_cloudwatch_event_bus.events.name
  arn            = module.events_to_kafka[0].lambda_function_arn
}
