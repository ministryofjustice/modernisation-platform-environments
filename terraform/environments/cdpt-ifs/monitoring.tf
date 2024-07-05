resource "aws_cloudwatch_metric_alarm" "lb_5xx_errors" {
  alarm_name          = "lb-5xx-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This metric monitors 5xx errors on the load balancer"
  alarm_actions       = [aws_sns_topic.lb_alarm_topic.arn]
  dimensions = {
    LoadBalancer = "${local.application_name}-lb"
  }
}

resource "aws_sns_topic" "lb_5xx_alarm_topic" {
  name = "lb_5xx_alarm_topic"
  kms_master_key_id = data.aws_kms_key.sns.id
}

# Pager duty integration

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
    aws_sns_topic.lb-5xx-errors
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
  sns_topics                = [aws_sns_topic.lb_5xx_alarm_topic.name]
  pagerduty_integration_key = local.pagerduty_integration_keys["cloudwatch_lb_alert"]
}

