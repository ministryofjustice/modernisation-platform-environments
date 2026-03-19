##############################################
### Secrets for Active Directory
##############################################

resource "random_password" "ad_admin_password" {
  count   = local.environment == "development" ? 1 : 0
  length  = 32
  special = false

  keepers = {
    directory_name = local.application_data.accounts[local.environment].ad_directory_name
  }

  lifecycle {
    ignore_changes = [
      keepers
    ]
  }
}

resource "aws_secretsmanager_secret" "ad_admin_password" {
  count                   = local.environment == "development" ? 1 : 0
  name                    = "${local.application_name}/${local.environment}/ad-admin-password"
  description             = "Active Directory admin password for ${local.application_name}-${local.environment}"
  recovery_window_in_days = 0

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}/${local.environment}/ad-admin-password" }
  )
}

resource "aws_secretsmanager_secret_version" "ad_admin_password" {
  count     = local.environment == "development" ? 1 : 0
  secret_id = aws_secretsmanager_secret.ad_admin_password[0].id
  secret_string = jsonencode(
    {
      username = "Admin"
      password = random_password.ad_admin_password[0].result
    }
  )

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}
