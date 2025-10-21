# DDoS Alarm
resource "aws_cloudwatch_metric_alarm" "this" {
  for_each            = var.resources
  alarm_name          = "DDoSDetected"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "DDoSDetected"
  namespace           = "AWS/DDoSProtection"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Triggers when AWS Shield Advanced detects a DDoS attack"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.module_ddos_alarm.arn]
  ok_actions          = [aws_sns_topic.module_ddos_alarm.arn]
  dimensions = {
    ResourceArn = each.value["arn"]
  }
}

# SNS topic for monitoring to send alarms to
data "aws_kms_key" "sns" {
  key_id = "alias/aws/sns"
}

resource "aws_sns_topic" "module_ddos_alarm" {
  name              = format("%s_ddos_alarm", var.application_name)
  kms_master_key_id = data.aws_kms_key.sns.id
}

## Pager duty integration
# Get the map of pagerduty integration keys from the modernisation platform account
data "aws_secretsmanager_secret" "pagerduty_integration_keys" {
  provider = aws.modernisation-platform
  name     = "pagerduty_integration_keys"
}
data "aws_secretsmanager_secret_version" "pagerduty_integration_keys" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.pagerduty_integration_keys.id
}

# Add a local to get the keys
locals {
  pagerduty_integration_keys = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
}

# link the sns topic to the service
module "pagerduty_core_alerts" {
  depends_on = [
    aws_sns_topic.module_ddos_alarm
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=d88bd90d490268896670a898edfaba24bba2f8ab" # v3.0.0
  sns_topics                = [aws_sns_topic.module_ddos_alarm.name]
  pagerduty_integration_key = local.pagerduty_integration_keys["ddos_cloudwatch"]
}
