# SNS Topic for Slack Alerts

resource "aws_sns_topic" "cloudwatch_slack" {
  name = "cloudwatch-slack-alerts"
}
#--Altering SNS
resource "aws_sns_topic" "guardduty_alerts" {
  name            = "${local.application_data.accounts[local.environment].app_name}-guardduty-alerts"
  delivery_policy = <<EOF
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
}