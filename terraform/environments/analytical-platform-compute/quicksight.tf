resource "aws_quicksight_account_subscription" "subscription" {
  account_name          = "analytical-platform-${local.environment}"
  authentication_method = "IAM_IDENTITY_CENTER"
  edition               = "ENTERPRISE"
  admin_group           = ["analytical-platform"]
  author_group          = ["analytical-platform"]
  notification_email    = local.environment_configuration.quicksight_notification_email
}
