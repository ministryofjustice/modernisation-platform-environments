# DDoS Alarm

resource "aws_cloudwatch_metric_alarm" "ddos_attack_external_ebsapps_alb" {
  alarm_name          = "DDoSDetectedEBSALB"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "DDoSDetected"
  namespace           = "AWS/DDoSProtection"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Triggers when AWS Shield Advanced detects a DDoS attack"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.ddos_alarm.arn]
  dimensions = {
    ResourceArn = aws_lb.ebsapps_lb.arn
  }
}
resource "aws_cloudwatch_metric_alarm" "ddos_attack_external_ebsapps_nlb" {
  alarm_name          = "DDoSDetectedEBSNLB"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "DDoSDetected"
  namespace           = "AWS/DDoSProtection"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Triggers when AWS Shield Advanced detects a DDoS attack"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.ddos_alarm.arn]
  dimensions = {
    ResourceArn = aws_lb.ebsapps_nlb.arn
  }
}

resource "aws_cloudwatch_metric_alarm" "ddos_attack_external_webgate_alb" {
  alarm_name          = "DDoSDetectedWebGateALB"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "DDoSDetected"
  namespace           = "AWS/DDoSProtection"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Triggers when AWS Shield Advanced detects a DDoS attack"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.ddos_alarm.arn]
  dimensions = {
    ResourceArn = aws_lb.webgate_public_lb.arn
  }
}
resource "aws_cloudwatch_metric_alarm" "ddos_attack_external_webgate_nlb" {
  alarm_name          = "DDoSDetectedWebGateNLB"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "DDoSDetected"
  namespace           = "AWS/DDoSProtection"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Triggers when AWS Shield Advanced detects a DDoS attack"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.ddos_alarm.arn]
  dimensions = {
    ResourceArn = aws_lb.webgate_nlb.arn
  }
}

/*
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
    aws_sns_topic.ddos_alarm
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v1.0.0"
  sns_topics                = [aws_sns_topic.ddos_alarm.name]
  pagerduty_integration_key = local.pagerduty_integration_keys["ddos_cloudwatch"]
}
*/