##
# Create password for AD root admin
##
resource "random_password" "ad_password" {
  length  = 30
  lower   = true
  upper   = true
  numeric = true
  special = true
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "ad_password" {
  #checkov:skip=CKV_AWS_149
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  name                    = "${var.networking[0].application}-ad-password"
  recovery_window_in_days = 0
  tags = merge(
    local.tags,
    {
      Name = "${var.networking[0].application}-ad-password"
    },
  )
}

data "aws_secretsmanager_secret_version" "ad_password" {
  secret_id = aws_secretsmanager_secret.ad_password.id
}
