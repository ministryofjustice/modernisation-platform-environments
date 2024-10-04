resource "aws_quicksight_account_subscription" "subscription" {
  account_name                     = "analytical-platform-${local.environment}"
  edition                          = "ENTERPRISE"
  authentication_method            = "IAM_IDENTITY_CENTER"
  iam_identity_center_instance_arn = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  admin_group                      = ["analytical-platform"]
  author_group                     = ["analytical-platform"]
  notification_email               = local.environment_configuration.quicksight_notification_email
  lifecycle {
    ignore_changes = [
      author_group, # not managed in code
      admin_group
    ]
}
