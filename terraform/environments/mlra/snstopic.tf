#Get Pagerduty keys from modplatform
  pagerduty_integration_keys = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)


# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "mlra-alerting-topic-nonprod" {
  name = "MLRA-Alerting-Topic-NonProd"
}

data "aws_secretsmanager_secret" "pagerduty_integration_keys" {
  provider = aws.modernisation-platform
  name     = "pagerduty_integration_keys"
}

data "aws_secretsmanager_secret_version" "pagerduty_integration_keys" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.pagerduty_integration_keys.id
}

module "pagerduty_core_alerts" {
  depends_on = [
    aws_sns_topic.mlra-alerting-topic-nonprod
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v1.0.0"
  sns_topics                = [aws_sns_topic.mlra-alerting-topic-nonprod.name]
  pagerduty_integration_key = local.pagerduty_integration_keys["core_alerts_cloudwatch"]
}
