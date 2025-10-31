data "aws_lb" "cdpt-ifs-lb" {
  name = "cdpt-ifs-lb"
}

resource "aws_sns_topic" "lb_5xx_alarm_topic" {
  name = "lb_5xx_alarm_topic"
}

locals {
  lb_short_arn = join("/", slice(split("/", module.lb_access_logs_enabled.load_balancer_arn), 1, 4))
}

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
  alarm_actions       = [aws_sns_topic.lb_5xx_alarm_topic.arn]
  dimensions = {
    LoadBalancer = local.lb_short_arn
  }
  treat_missing_data = "notBreaching"
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
    aws_sns_topic.lb_5xx_alarm_topic
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
  sns_topics                = [aws_sns_topic.lb_5xx_alarm_topic.name]
  pagerduty_integration_key = local.pagerduty_integration_keys["cdpt-ifs-alarms"]
}

output "lb_short_arn" {
  value = local.lb_short_arn
}
