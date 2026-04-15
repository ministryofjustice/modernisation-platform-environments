# Flow: CloudTrail → CloudWatch Logs → CW Metric Filter → CW Alarm → SNS → PagerDuty
# Uses the existing CloudTrail log group ("cloudtrail") deployed by the MP baselines module.

# ---------------------------------------------------------------------------
# Existing CloudTrail log group (deployed by MP baselines)
# ---------------------------------------------------------------------------

data "aws_cloudwatch_log_group" "cloudtrail" {
  name = "cloudtrail"
}

# ---------------------------------------------------------------------------
# SNS Topic — send security alerts to PagerDuty
# ---------------------------------------------------------------------------

resource "aws_sns_topic" "high_priority_alerts" {
  name = "high-priority-alerts"
  tags = local.tags
}

# Allow CloudWatch Alarms to publish to this topic.
resource "aws_sns_topic_policy" "high_priority_alerts" {
  arn = aws_sns_topic.high_priority_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudWatchAlarmsPublish"
      Effect    = "Allow"
      Principal = { Service = "cloudwatch.amazonaws.com" }
      Action    = "sns:Publish"
      Resource  = aws_sns_topic.high_priority_alerts.arn
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
      }
    }]
  })
}

resource "aws_sns_topic_subscription" "high_priority_alerts_pagerduty" {
  topic_arn = aws_sns_topic.high_priority_alerts.arn
  protocol  = "https"
  endpoint  = "https://events.pagerduty.com/integration/${data.aws_secretsmanager_secret_version.pagerduty_integration_key.secret_string}/enqueue"
}

# ---------------------------------------------------------------------------
# CloudWatch Log Metric Filter + Alarm — new IAM user creation
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_log_metric_filter" "iam_user_created" {
  name           = "container-platform-iam-user-creation"
  log_group_name = data.aws_cloudwatch_log_group.cloudtrail.name
  pattern        = "{($.eventName = \"CreateUser\") && ($.errorCode NOT EXISTS)}"

  metric_transformation {
    name      = "container-platform-iam-user-creation"
    namespace = "ContainerPlatformSecurityAlerts"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "iam_user_created" {
  alarm_name        = "A New IAM User Created in ${terraform.workspace}"
  alarm_description = "A new IAM user was created in AWS account ${terraform.workspace}. IAM users should not be created and please investigate immediately."
  alarm_actions     = [aws_sns_topic.high_priority_alerts.arn]

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.iam_user_created.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.iam_user_created.metric_transformation[0].namespace
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  treat_missing_data  = "notBreaching"

  tags = local.tags
}