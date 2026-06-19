##############################################
### RADIUS Server Secrets
###
### Secrets for RADIUS server, LinOTP portal,
### and MariaDB database
##############################################

##############################################
### RADIUS Shared Secret
##############################################

resource "random_password" "radius_shared_secret" {
  length  = 32
  special = true
}

resource "aws_secretsmanager_secret" "radius_shared_secret" {
  name_prefix             = "${local.application_name}-${local.environment}-radius-secret-"
  description             = "RADIUS shared secret for WorkSpaces MFA"
  recovery_window_in_days = 0

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-radius-secret"
      "Type" = "RADIUS"
    }
  )
}

resource "aws_secretsmanager_secret_version" "radius_shared_secret" {
  secret_id     = aws_secretsmanager_secret.radius_shared_secret.id
  secret_string = random_password.radius_shared_secret.result
}

##############################################
### LinOTP Admin Password
##############################################

resource "random_password" "linotp_admin_password" {
  length  = 32
  special = true
}

resource "aws_secretsmanager_secret" "linotp_admin_password" {
  name_prefix             = "${local.application_name}-${local.environment}-linotp-admin-"
  description             = "LinOTP admin password for MFA portal"
  recovery_window_in_days = 0

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-linotp-admin-password"
      "Type" = "LinOTP"
    }
  )
}

resource "aws_secretsmanager_secret_version" "linotp_admin_password" {
  secret_id     = aws_secretsmanager_secret.linotp_admin_password.id
  secret_string = random_password.linotp_admin_password.result
}

##############################################
### MariaDB Root Password
##############################################

resource "random_password" "mariadb_root_password" {
  length  = 32
  special = true
}

resource "aws_secretsmanager_secret" "mariadb_root_password" {
  name_prefix             = "${local.application_name}-${local.environment}-mariadb-root-"
  description             = "MariaDB root password for LinOTP database"
  recovery_window_in_days = 0

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-mariadb-root-password"
      "Type" = "MariaDB"
    }
  )
}

resource "aws_secretsmanager_secret_version" "mariadb_root_password" {
  secret_id     = aws_secretsmanager_secret.mariadb_root_password.id
  secret_string = random_password.mariadb_root_password.result
}
