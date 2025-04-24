data "aws_cloudwatch_event_source" "this" {
  name_prefix = var.event_source
}

resource "aws_cloudwatch_event_bus" "this" {
  name              = data.aws_cloudwatch_event_source.this.name
  event_source_name = data.aws_cloudwatch_event_source.this.name
}

resource "aws_cloudwatch_event_rule" "this" {
  name           = "all-auth0-to-cloudwatch"
  event_bus_name = aws_cloudwatch_event_bus.this.name

  event_pattern = jsonencode({
    "source" : [{
      "prefix" : "aws.partner/auth0.com"
    }]
  })
}

resource "aws_cloudwatch_event_target" "this" {
  rule           = aws_cloudwatch_event_rule.this.name
  arn            = var.log_group_arn
  event_bus_name = aws_cloudwatch_event_bus.this.name
}