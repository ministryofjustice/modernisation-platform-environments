data "aws_cloudwatch_event_source" "this" {
  name_prefix = var.event_source
}

resource "aws_cloudwatch_event_bus" "this" {
  name              = data.aws_cloudwatch_event_source.this.name
  event_source_name = data.aws_cloudwatch_event_source.this.name
}

resource "aws_cloudwatch_event_rule" "this" {
  name        = "all-auth0-to-cloudwatch"

  event_pattern = jsonencode({
    "source": [{
        "prefix": "aws.partner/auth0.com"
    }]
  })
}

resource "aws_cloudwatch_event_target" "this" {
  rule      = aws_cloudwatch_event_rule.this.name
  arn       = "arn:aws:logs:eu-west-2:211125434264:log-group:/aws/events/LogsFromOperationsEngineeringAuth0"
}