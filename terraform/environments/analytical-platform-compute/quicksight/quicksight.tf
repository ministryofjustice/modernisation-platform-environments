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
}

resource "aws_quicksight_vpc_connection" "shared_vpc_connection" {
  name               = "${var.networking[0].business-unit}-${local.environment}"
  vpc_connection_id  = "${var.networking[0].business-unit}-${local.environment}"
  role_arn           = module.quicksight_vpc_connection_iam_role.iam_role_arn
  security_group_ids = [module.quicksight_shared_vpc_security_group.security_group_id]
  subnet_ids         = toset(data.aws_subnets.shared_private.ids)
}
