#==================================================================================================
# Setup for monitoring/alerting
#==================================================================================================

# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "nomis_alarms" {
  name = "nomis_alarms"
}

## Pager duty integration

# integration "nomis_alarms" has to be set up manually in pagerduty by the Modernisation Platform team
# alarms will currently appear in the dso_alerts_modernisation_platform slack channel

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
    aws_sns_topic.nomis_alarms
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v1.0.0"
  sns_topics                = [aws_sns_topic.nomis_alarms.name]
  pagerduty_integration_key = local.pagerduty_integration_keys["nomis_alarms"]
}
