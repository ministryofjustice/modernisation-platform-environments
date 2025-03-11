resource "aws_cloudwatch_event_rule" "aws_health" {
  count = local.is-development ? 1 : 0

  name = "aws-health"

  event_pattern = jsonencode({
    source = [
      "aws.health"
    ]
  })
}
