#==================================================================================================
# Setup for monitoring/alerting
#==================================================================================================

# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "nomis_alarms" {
  name = "nomis_alarms"
}

# integration "nomis_alarms" has to be set up manually in pagerduty by the Modernisation Platform team
# alarms will currently appear in the dso_alerts_modernisation_platform slack channel

resource "aws_sns_topic" "nomis_nonprod_alarms" {
  name = "nomis_nonprod_alarms"
}

# integration "nomis_nonprod_alarms" has to be set up manually in pagerduty by the Modernisation Platform team
# nomis_nonprod_alarms will currently appear in the dso_alerts_devtest_modernisation_platform slack channel

## Pager duty integration

# Add a local to get the keys
locals {
  pagerduty_integration_keys = module.environment.pagerduty_integration_keys
}

# link the sns topic to the service

module "pagerduty_integration_prod" {
  depends_on = [
    aws_sns_topic.nomis_alarms
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v1.0.0"
  sns_topics                = [aws_sns_topic.nomis_alarms.name]
  pagerduty_integration_key = local.pagerduty_integration_keys["nomis_alarms"]
}

module "pagerduty_integration_nonprod" {
  depends_on = [
    aws_sns_topic.nomis_nonprod_alarms
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v1.0.0"
  sns_topics                = [aws_sns_topic.nomis_nonprod_alarms.name]
  pagerduty_integration_key = local.pagerduty_integration_keys["nomis_nonprod_alarms"]
}
