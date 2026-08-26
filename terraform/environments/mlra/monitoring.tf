resource "aws_cloudwatch_metric_alarm" "ddos_attack_external" {
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
  alarm_actions       = [aws_sns_topic.mlra_ddos_alarm.arn]
  dimensions = {
    ResourceArn = module.alb.load_balancer.arn
  }
}

# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "mlra_ddos_alarm" {
  name              = "mlra_ddos_alarm"
  kms_master_key_id = data.aws_kms_alias.sns.id
}

data "aws_kms_alias" "sns" {
  name = "alias/aws/sns"
}

module "pagerduty_core_alerts" {
  #checkov:skip=CKV_TF_1:TODO Will be addressed as part of https://dsdmoj.atlassian.net/browse/LASB-3390
  depends_on = [
    aws_sns_topic.mlra_ddos_alarm
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
  sns_topics                = [aws_sns_topic.mlra_ddos_alarm.name]
  pagerduty_integration_key = local.pagerduty_integration_keys["ddos_cloudwatch"]
}
