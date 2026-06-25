# ---------------------------------------------------------------------------------------------------------------------
# SSM Parameter Store
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ssm_parameter" "drone_incursion_alert_emails" {
  count = contains(local.deploy_to, local.environment) ? 1 : 0

  name        = "/streaming-poc-maf/${local.environment}/drone-incursion-alert-emails"
  description = "Email recipients for drone incursion SNS alerts"
  type        = "StringList"
  value       = "stuart.logan@justice.gov.uk,vishal.shah@justice.gov.uk"

  tags = local.extended_tags
}

# # TODO: uncomment if a sender ID is created and sms is out of sandbox mode.
# resource "aws_ssm_parameter" "drone_incursion_alert_phone_numbers" {
#   count = contains(local.deploy_to, local.environment) ? 1 : 0
#
#   name        = "/streaming-poc-maf/${local.environment}/drone-incursion-alert-phone-numbers"
#   description = "SMS recipients for drone incursion SNS alerts"
#   type        = "SecureString"
#   value       = ""
#
#   tags = local.extended_tags
# }
