# alpha-analytics-moj

data "aws_cloudwatch_event_source" "alpha-analytics-moj" {
  name_prefix = "aws.partner/auth0.com/alpha-analytics-moj-9790e567-420a-48b2-b978-688dd998d26c/auth0.logs"
}

resource "aws_cloudwatch_event_bus" "alpha-analytics-moj" {
  name              = data.aws_cloudwatch_event_source.alpha-analytics-moj.name
  event_source_name = data.aws_cloudwatch_event_source.alpha-analytics-moj.name
}

resource "aws_cloudwatch_event_rule" "alpha-analytics-moj-auth0" {
  name        = "alpha-analytics-moj-auth0"

  event_pattern = jsonencode({
    "source": [{
        "prefix": "aws.partner/auth0.com"
    }]
  })
}

resource "aws_cloudwatch_event_target" "alpha-analytics-moj-auth0-target" {
  rule      = aws_cloudwatch_event_rule.alpha-analytics-moj-auth0.name
  arn       = "arn:aws:logs:eu-west-2:211125434264:log-group:/aws/events/LogsFromOperationsEngineeringAuth0"
}

# justice-cloud-platform

data "aws_cloudwatch_event_source" "justice-cloud-platform" {
  name_prefix = "aws.partner/auth0.com/justice-cloud-platform-9bea4c89-7006-4060-94f8-ef7ed853d946/auth0.logs"
}

resource "aws_cloudwatch_event_bus" "justice-cloud-platform" {
  name              = data.aws_cloudwatch_event_source.justice-cloud-platform.name
  event_source_name = data.aws_cloudwatch_event_source.justice-cloud-platform.name
}

resource "aws_cloudwatch_event_rule" "justice-cloud-platform-auth0" {
  name        = "justice-cloud-platform-auth0"

  event_pattern = jsonencode({
    "source": [{
        "prefix": "aws.partner/auth0.com"
    }]
  })
}

resource "aws_cloudwatch_event_target" "justice-cloud-platform-auth0-target" {
  rule      = aws_cloudwatch_event_rule.justice-cloud-platform-auth0.name
  arn       = "arn:aws:logs:eu-west-2:211125434264:log-group:/aws/events/LogsFromOperationsEngineeringAuth0"
}

# ministryofjustice

data "aws_cloudwatch_event_source" "ministryofjustice" {
  name_prefix = "aws.partner/auth0.com/ministryofjustice-775267e6-72e7-46a5-9059-a396cd0625e7/auth0.logs"
}

resource "aws_cloudwatch_event_bus" "ministryofjustice" {
  name              = data.aws_cloudwatch_event_source.ministryofjustice.name
  event_source_name = data.aws_cloudwatch_event_source.ministryofjustice.name
}

resource "aws_cloudwatch_event_rule" "ministryofjustice-auth0" {
  name        = "ministryofjustice-auth0"

  event_pattern = jsonencode({
    "source": [{
        "prefix": "aws.partner/auth0.com"
    }]
  })
}

resource "aws_cloudwatch_event_target" "ministryofjustice-auth0-target" {
  rule      = aws_cloudwatch_event_rule.ministryofjustice-auth0.name
  arn       = "arn:aws:logs:eu-west-2:211125434264:log-group:/aws/events/LogsFromOperationsEngineeringAuth0"
}

# operations-engineering

data "aws_cloudwatch_event_source" "operations-engineering" {
  name_prefix = "aws.partner/auth0.com/operations-engineering-4d9a5624-861c-4871-981e-fce33be08149/auth0.logs"
}

resource "aws_cloudwatch_event_bus" "operations-engineering" {
  name              = data.aws_cloudwatch_event_source.operations-engineering.name
  event_source_name = data.aws_cloudwatch_event_source.operations-engineering.name
}

resource "aws_cloudwatch_event_rule" "operations-engineering-auth0" {
  name        = "operations-engineering-auth0"

  event_pattern = jsonencode({
    "source": [{
        "prefix": "aws.partner/auth0.com"
    }]
  })
}

resource "aws_cloudwatch_event_target" "operations-engineering-auth0-target" {
  rule      = aws_cloudwatch_event_rule.operations-engineering-auth0.name
  arn       = "arn:aws:logs:eu-west-2:211125434264:log-group:/aws/events/LogsFromOperationsEngineeringAuth0"
}