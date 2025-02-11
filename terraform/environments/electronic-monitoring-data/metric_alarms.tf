#tfsec:ignore:avd-aws-0136 No encryption is enabled on the SNS topic
resource "aws_sns_topic" "lambda_failure" {
  name              = "lambda-failures"
  kms_master_key_id = "alias/aws/sns"
}

# Alarm - "there is at least one error in a minute in AWS Lambda functions"
module "all_lambdas_errors_alarm" {
  #checkov:skip=CKV_TF_1:Ensure Terraform module sources use a commit hash. No commit hash on this module
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.0"

  alarm_name          = "all-lambdas-errors"
  alarm_description   = "Lambdas with errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 0
  period              = 60
  unit                = "Count"

  namespace   = "AWS/Lambda"
  metric_name = "Errors"
  statistic   = "Maximum"

  alarm_actions = [aws_sns_topic.lambda_failure.arn]
}

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
  sns_names_map              = tomap({ "lambda_failure" : aws_sns_topic.lambda_failure.name })
}

# link the sns topic to the service
module "pagerduty_core_alerts" {
  #checkov:skip=CKV_TF_1:Ensure Terraform module sources use a commit hash. No commit hash on this module
  depends_on = [
    aws_sns_topic.lambda_failure
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
  sns_topics                = [for key, value in local.sns_names_map : value]
  pagerduty_integration_key = local.pagerduty_integration_keys["electronic_monitoring_data_alarms"]
}
