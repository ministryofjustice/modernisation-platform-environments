resource "aws_cloudwatch_event_rule" "aws_health" {
  count = local.is-development ? 1 : 0

  name = "aws-health"

  event_pattern = jsonencode({
    source = [
      "aws.health"
    ]
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  count = local.is-development ? 1 : 0

  rule      = aws_cloudwatch_event_rule.aws_health[0].name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.aws_health[0].arn
}


resource "aws_sns_topic" "aws_health" {
  count = local.is-development ? 1 : 0

  name = "aws-health"
}
