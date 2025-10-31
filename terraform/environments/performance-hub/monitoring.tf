# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "alerts_topic" {
  name = "alerts_topic"
}

resource "aws_sns_topic" "ddos_topic" {
  name = "ddos_topic"
}


# DDoS Alarm
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
  alarm_actions       = [aws_sns_topic.ddos_topic.arn]
  dimensions = {
    ResourceArn = aws_lb.external.arn
  }
}

# load balancer alarm (5xx)
resource "aws_cloudwatch_metric_alarm" "lb_5xx_errors" {
  alarm_name         = "${local.application_name}-lb-5xx-error-alarm"
  alarm_description  = "This alarm will trigger if we receive 4 5XX elb alerts in a 5-minute period."
  namespace          = "AWS/ApplicationELB"
  metric_name        = "HTTPCode_ELB_5XX_Count"
  statistic          = "Sum"
  period             = 300
  evaluation_periods = 5
  threshold          = 1
  treat_missing_data = "notBreaching"
  alarm_actions      = [aws_sns_topic.alerts_topic.arn]
  ok_actions         = [aws_sns_topic.alerts_topic.arn]
  dimensions = {
    LoadBalancer = aws_lb.external.name
  }
  comparison_operator = "GreaterThanThreshold"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-lb-5xx-error-alarm"
    },
  )
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

# link the SNS topics to the PagerDuty service
# https://github.com/ministryofjustice/modernisation-platform/blob/main/terraform/pagerduty/member-services-integrations.tf
# https://github.com/ministryofjustice/modernisation-platform/blob/main/terraform/pagerduty/aws.tf#L17
module "pagerduty_alerts_app" {
  depends_on = [
    aws_sns_topic.alerts_topic
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
  sns_topics                = [aws_sns_topic.alerts_topic.name]
  pagerduty_integration_key = local.pagerduty_integration_keys["performance_hub_prod_alarms"]
}

module "pagerduty_alerts_ddos" {
  depends_on = [
    aws_sns_topic.ddos_topic
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
  sns_topics                = [aws_sns_topic.ddos_topic.name]
  pagerduty_integration_key = local.pagerduty_integration_keys["ddos_cloudwatch"]
}