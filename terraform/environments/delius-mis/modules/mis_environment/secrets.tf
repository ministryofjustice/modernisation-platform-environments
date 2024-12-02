#### This file can be used to store secrets specific to the member account ####
#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "ad_username" {
  #checkov:skip=CKV_AWS_149 "ignore"
  name                    = "${var.env_name}-legacy-ad-username"
  recovery_window_in_days = 0

  tags = var.tags
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "ad_password" {
  #checkov:skip=CKV_AWS_149 "ignore"
  name                    = "${var.env_name}-legacy-ad-password"
  recovery_window_in_days = 0

  tags = var.tags
}
