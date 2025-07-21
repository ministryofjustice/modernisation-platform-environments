locals {

  db_instance_id = local.application_name

  rds_oracle_metrics = [
    "CPUUtilization",
    "DatabaseConnections",
    "FreeStorageSpace",
    "FreeableMemory",
    "ReadIOPS",
    "WriteIOPS",
    "ReadLatency",
    "WriteLatency"
  ]

  common_rds_config = {
    namespace           = "AWS/RDS"
    statistic           = "Average"
    period              = 300
    evaluation_periods  = 1
    threshold           = 80
    comparison_operator = "GreaterThanThreshold"
  }

  alarm_name_prefix = "${local.application_name}-alarm"
}

resource "aws_cloudwatch_metric_alarm" "rds_alarms" {
  for_each = toset(local.rds_oracle_metrics)

  alarm_name          = "${local.alarm_name_prefix}-${each.key}"
  comparison_operator = local.common_rds_config.comparison_operator
  evaluation_periods  = local.common_rds_config.evaluation_periods
  metric_name         = each.key
  namespace           = local.common_rds_config.namespace
  period              = local.common_rds_config.period
  statistic           = local.common_rds_config.statistic
  threshold           = local.common_rds_config.threshold
  alarm_description   = "Alarm for RDS Oracle metric: ${each.key}"
  alarm_actions       = [aws_sns_topic.maatdb_alerting_topic.arn]
  ok_actions          = [aws_sns_topic.maatdb_alerting_topic.arn]

  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_id
  }

  depends_on = [
    module.rds,
    aws_sns_topic.maatdb_alerting_topic
  ]

}

# Cloudwatch resources for the FTP and ZIP Lambdas

# Note that we only build these if the rest of the lambda infrastructure is flagged for creation via local.build_ftp

resource "aws_cloudwatch_metric_alarm" "ftp_lambda_error" {
  count               = local.build_ftp ? 1 : 0
  alarm_name          = "${aws_lambda_function.ftp[0].function_name}-errors"
  alarm_description   = "Alarm for ${aws_lambda_function.ftp[0].function_name} function errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "missing"

  dimensions = {
    FunctionName = aws_lambda_function.ftp[0].function_name
  }

  alarm_actions = [aws_sns_topic.maatdb_alerting_topic.arn] # optional
}

resource "aws_cloudwatch_metric_alarm" "zip_lambda_error" {
  count               = local.build_ftp ? 1 : 0
  alarm_name          = "${aws_lambda_function.zip[0].function_name}-errors"
  alarm_description   = "Alarm for ${aws_lambda_function.zip[0].function_name} function errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "missing"

  dimensions = {
    FunctionName = aws_lambda_function.zip[0].function_name
  }

  alarm_actions = [aws_sns_topic.maatdb_alerting_topic.arn]
}



####### CLOUDWATCH PAGERDUTY ALERTING

# Note - this is using the same integration for the MAAT application & so the same slack channels.

# Get the map of pagerduty integration keys from the modernisation platform account

data "aws_secretsmanager_secret" "maatdb_pagerduty_integration_keys" {
  provider = aws.modernisation-platform
  name     = "pagerduty_integration_keys"
}

data "aws_secretsmanager_secret_version" "maatdb_pagerduty_integration_keys" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.maatdb_pagerduty_integration_keys.id
}

# Add a local to get the keys. Note we are reusing the MAAT application's PagerDuty Integration & Key Name.
locals {
  maatdb_pagerduty_integration_keys     = jsondecode(data.aws_secretsmanager_secret_version.maatdb_pagerduty_integration_keys.secret_string)
  maatdb_pagerduty_integration_key_name = local.application_data.accounts[local.environment].pagerduty_integration_key_name
}


# Create SNS topic
resource "aws_sns_topic" "maatdb_alerting_topic" {
  #checkov:skip=CKV_AWS_26:"Not required as only standard RDS metrics being alerted on."
  name = "${local.application_name}-${local.environment}-alerting-topic"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-alerting-topic"
    }
  )
}

# link the sns topic to the service
module "maatdb_pagerduty_core_alerts" {
  depends_on = [
    aws_sns_topic.maatdb_alerting_topic
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=0179859e6fafc567843cd55c0b05d325d5012dc4" #v2.0.0
  sns_topics                = [aws_sns_topic.maatdb_alerting_topic.name]
  pagerduty_integration_key = local.maatdb_pagerduty_integration_keys[local.maatdb_pagerduty_integration_key_name]
}