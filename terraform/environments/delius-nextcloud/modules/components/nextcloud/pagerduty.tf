# Add a local to get the keys
# locals {
#   pagerduty_integration_keys = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
#   pagerduty_integration_key  = is-prod ? "delius_core_prod_alarms" : "delius_core_nonprod_alarms"
# }
# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "nextcloud_alarms" {
  name = "nextcloud-alarms-${var.env_name}"
}

# Pager duty integration

# Get the map of pagerduty integration keys from the modernisation platform account
# data "aws_secretsmanager_secret" "pagerduty_integration_keys" {
#   provider = aws.modernisation-platform
#   name     = "pagerduty_integration_keys"
# }

# data "aws_secretsmanager_secret_version" "pagerduty_integration_keys" {
#   provider  = aws.modernisation-platform
#   secret_id = data.aws_secretsmanager_secret.pagerduty_integration_keys.id
# }

# link the sns topic to the service
# module "pagerduty_core_alerts" {
#
#   depends_on = [
#     aws_sns_topic.delius_core_alarms
#   ]
#
#   source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
#   sns_topics                = [aws_sns_topic.delius_core_alarms.name]
#   pagerduty_integration_key = var.pagerduty_integration_key
# }
#