resource "aws_sns_topic" "lb_alarm_topic" {
  name = "lb_alarm_topic"
}

module "slack_alerts_url" {
  for_each = local.enable_slack_alerts ? { "enabled": "enabled" } : {}
  source               = "./modules/baseline/secrets_manager"
  name                 = "${local.application_name}-slack-alerts-url-${local.environment}"
  description          = "IFS LoadBalancer slack alerts URL"
  type                 = "MONO"
  secret_value         = "http://Placeholder_webhook_URL"
  ignore_secret_string = true

  tags = merge(
    local.all_tags,
    {
      Resource_Type  = "Secret"
      Name           = "${local.application_name}-slack-alerts-url-${local.environment}"
    }
  )
}

data "aws_secretsmanager_secret" "slack_integration" {
  for_each = local.enable_slack_alerts ? { "enabled": "enabled" } : {}
  depends_on = [module.slack_alerts_url]
  name       = "${local.project}-slack-alerts-url-${local.environment}"
}

data "aws_secretsmanager_secret_version" "slack_integration" {
  for_each = local.enable_slack_alerts ? { "enabled": "enabled" } : {}
  secret_id = data.aws_secretsmanager_secret.slack_integration[0].id
}

resource "aws_sns_topic_subscription" "slack_subscription" {
  depends_on = [data.aws_secretsmanager_secret_version.slack_integration]
  topic_arn = aws_sns_topic.lb_alarm_topic.arn
  protocol  = "https"
  endpoint  = data.aws_secretsmanager_secret_version.slack_integration["enabled"].secret_string
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
  alarm_actions       = [aws_sns_topic.lb_alarm_topic.arn]

  dimensions = {
    LoadBalancer = "${local.application_name}-lb"
  }
}






