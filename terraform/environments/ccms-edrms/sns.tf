# SNS Topic for Slack Alerts

resource "aws_sns_topic" "cloudwatch_slack" {
  name              = "cloudwatch-slack-alerts"
  delivery_policy   = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultRequestPolicy": {
      "headerContentType": "text/plain; charset=UTF-8"
    }
  }
}
EOF
  kms_master_key_id = aws_kms_key.cloudwatch_sns_alerts_key.id
  tags = merge(local.tags,
    { Name = "cloudwatch-slack-alerts" }
  )
}

resource "aws_sns_topic_policy" "cloudwatch_slack" {
  arn    = aws_sns_topic.cloudwatch_slack.arn
  policy = data.aws_iam_policy_document.cloudwatch_alerting_sns.json
}

#--Altering SNS
resource "aws_sns_topic" "guardduty_alerts" {
  name              = "${local.application_data.accounts[local.environment].app_name}-guardduty-alerts"
  delivery_policy   = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultRequestPolicy": {
      "headerContentType": "text/plain; charset=UTF-8"
    }
  }
}
EOF
  kms_master_key_id = aws_kms_key.cloudwatch_sns_alerts_key.id
  tags = merge(local.tags,
    { Name = "cloudwatch-slack-alerts" }
  )
}

resource "aws_sns_topic_policy" "guardduty_default" {
  arn    = aws_sns_topic.guardduty_alerts.arn
  policy = data.aws_iam_policy_document.guardduty_alerting_sns.json
}

# RDS minor upgrade notification changes 
# SNS topic for RDS maintenance events

resource "aws_sns_topic" "tds_maintenance_topic" {
  name              = "${local.application_name}-${local.environment}-tds-maintenance-topic"
  kms_master_key_id = aws_kms_key.sns_rds_events.arn
  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-tds-maintenance-topic"
  })
}

# SNS Topic policy 

resource "aws_sns_topic_subscription" "rds_to_slack_lambda" {
  topic_arn = aws_sns_topic.tds_maintenance_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.cloudwatch_sns.arn

  depends_on = [
    aws_lambda_permission.allow_rds_sns_invoke
  ]
}
