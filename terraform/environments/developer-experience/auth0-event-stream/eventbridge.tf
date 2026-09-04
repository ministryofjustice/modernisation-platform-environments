module "source_eventbridge" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eventbridge.git?ref=f9934726324c988f823682884b4fa003586a7b6f" # v4.3.2

  providers = {
    aws = aws.us-east-1
  }

  bus_name           = data.aws_cloudwatch_event_source.this[0].name
  event_source_name  = data.aws_cloudwatch_event_source.this[0].name
  kms_key_identifier = module.source_kms_key[0].key_arn

  create_log_delivery = false
  create_pipes        = false
  create_schedules    = false
  create_targets      = false
  create_rules        = false
  create_role         = false
  create_permissions  = false
}

resource "aws_cloudwatch_event_rule" "source" {
  count = local.is-production ? 1 : 0

  provider = aws.us-east-1

  name           = local.component_name
  event_bus_name = data.aws_cloudwatch_event_source.this[0].name

  event_pattern = jsonencode({
    source      = [data.aws_cloudwatch_event_source.this[0].name]
    detail-type = ["Auth0 log"]
  })
}

resource "aws_cloudwatch_event_target" "cross_region" {
  count = local.is-production ? 1 : 0

  provider = aws.us-east-1

  rule           = aws_cloudwatch_event_rule.source[0].name
  event_bus_name = data.aws_cloudwatch_event_source.this[0].name
  arn            = module.destination_eventbridge[0].eventbridge_bus_arn
  role_arn       = module.cross_region_iam_role[0].arn
}

module "destination_eventbridge" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eventbridge.git?ref=f9934726324c988f823682884b4fa003586a7b6f" # v4.3.2

  bus_name           = local.component_name
  kms_key_identifier = module.destination_kms_key[0].key_arn

  attach_kinesis_firehose_policy = true
  kinesis_firehose_target_arns   = [aws_kinesis_firehose_delivery_stream.this[0].arn]

  rules = {
    auth0_logs = {
      description = "Route Auth0 log stream events to S3 via Firehose"
      event_pattern = jsonencode({
        source      = [data.aws_cloudwatch_event_source.this[0].name]
        detail-type = ["Auth0 log"]
      })
    }
  }

  targets = {
    auth0_logs = [
      {
        name = "auth0-log-archive"
        arn  = aws_kinesis_firehose_delivery_stream.this[0].arn
      }
    ]
  }
}
