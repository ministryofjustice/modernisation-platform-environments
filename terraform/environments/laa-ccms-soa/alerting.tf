#--Alerting Lambda
data "archive_file" "alerts" {
  type        = "zip"
  source_file = "./templates/alerting.py"
  output_path = "./templates/alerting"
}

resource "aws_lambda_function" "alerts" {
  filename         = data.archive_file.alerts.output_path
  function_name    = "${local.application_data.accounts[local.environment].app_name}-soa-alerting"
  role             = aws_iam_role.alerting_lambda.arn
  handler          = "alerting.lambda_handler"
  source_code_hash = data.archive_file.alerts.output_base64sha256
  runtime          = "python3.8"
  environment {
    variables = {
      LOG_EVENTS        = "False"
      SLACK_CHANNEL     = local.application_data.accounts[local.environment].alerting_slack_channel
      SLACK_EMOJI       = ":aws2:"
      SLACK_USERNAME    = local.application_data.accounts[local.environment].alerting_slack_user
      SLACK_WEBHOOK_URL = data.aws_secretsmanager_secret_version.alerting_webhook_url.secret_string
    }
  }
}

resource "aws_lambda_permission" "alerts_sns_invoke" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alerts.arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}

resource "aws_sns_topic_subscription" "alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.alerts.arn
}

#--Altering SNS
resource "aws_sns_topic" "alerts" {
  name            = "${local.application_data.accounts[local.environment].app_name}-alerts"
  policy          = data.aws_iam_policy_document.alerting_sns.json
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
