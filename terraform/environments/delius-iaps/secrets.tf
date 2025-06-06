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

##
# Oracle Database DBA Secret
##
#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "database_dba_passwords" {
  #checkov:skip=CKV_AWS_149
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  name                    = local.dba_secret_name
  description             = "DBA Users Credentials"
  recovery_window_in_days = 0

  tags = merge(
    local.tags,
    {
      Name = local.dba_secret_name
    },
  )
}

resource "random_password" "dbsnmp_password" {
  length  = 30
  lower   = true
  upper   = true
  numeric = true
  special = true
}

resource "random_password" "oem_agentreg_password" {
  length  = 30
  lower   = true
  upper   = true
  numeric = true
  special = true
}

resource "aws_secretsmanager_secret_version" "database_dba_passwords" {
  secret_id     = aws_secretsmanager_secret.database_dba_passwords.id
  secret_string = jsonencode({
    dbsnmp = {
      username = "dbsnmp"
      password = random_password.dbsnmp_password.result
    }
    oem_agentreg = {
      username = "oem_agentreg"
      password = random_password.oem_agentreg_password.result
    }
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Lookup latest version of the combined secret
data "aws_secretsmanager_secret_version" "dba_passwords" {
  secret_id = aws_secretsmanager_secret.database_dba_passwords.id
}

# Decode the JSON and extract only the OEM Agent password
locals {
  dba_passwords        = jsondecode(data.aws_secretsmanager_secret_version.dba_passwords.secret_string)
  oem_agent_password   = local.dba_passwords.oem_agentreg.password
}