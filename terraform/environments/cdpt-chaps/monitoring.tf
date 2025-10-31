data "aws_lb" "cdpt-chaps-lb" {
  name = "cdpt-chaps-lb"
}

locals {
  lb_short_arn = join("/", slice(split("/", module.lb_access_logs_enabled.load_balancer_arn), 1, 4))
}

# LoadBalancer Alarm

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
  alarm_actions       = [aws_sns_topic.cdpt_chaps_ddos_alarm.arn]
  dimensions = {
    LoadBalancer = local.lb_short_arn
  }
  treat_missing_data = "notBreaching"
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
  alarm_actions       = [aws_sns_topic.cdpt_chaps_ddos_alarm.arn]
  dimensions = {
    ResourceArn = module.lb_access_logs_enabled.load_balancer.arn
  }
}



# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "cdpt_chaps_ddos_alarm" {
  name              = "cdpt_chaps_ddos_alarm"
  kms_master_key_id = data.aws_kms_alias.sns.id
}

data "aws_kms_alias" "sns" {
  name = "alias/aws/sns"
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
    aws_sns_topic.cdpt_chaps_ddos_alarm
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
  sns_topics                = [aws_sns_topic.cdpt_chaps_ddos_alarm.name]
  pagerduty_integration_key = local.pagerduty_integration_keys["ddos_cloudwatch"]
}