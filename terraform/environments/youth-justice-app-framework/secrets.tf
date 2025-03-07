#### This file can be used to store secrets specific to the member account ####
#### Secrets can be manually edited once created here ####

#Auto-admit create secret but later manually change value
resource "aws_secretsmanager_secret" "auto_admit_secret" {
  #checkov:skip=CKV2_AWS_57:todo add rotation if needed
  name        = "yjaf-auto-admit"
  description = "Password for autoadmin user"
  kms_key_id  = module.kms.key_id
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "auto_admit_version" {
  secret_id     = aws_secretsmanager_secret.auto_admit_secret.id
  secret_string = "dummy"
  lifecycle {
    ignore_changes = [secret_string]
  }
}


resource "aws_secretsmanager_secret" "LDAP_administration_secret" {
  #checkov:skip=CKV2_AWS_57:todo add rotation if needed
  name        = "LDAP-administration-user"
  description = "Password for LDAP-administration"
  kms_key_id  = module.kms.key_id
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "LDAP_administration_version" {
  secret_id     = aws_secretsmanager_secret.LDAP_administration_secret.id
  secret_string = "dummy"
  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "LDAP_DC_secret" {
  #checkov:skip=CKV2_AWS_57:doesn't need rotation
  name        = "LDAP-DC-Connection-String"
  description = "DC connection string for LDAP"
  kms_key_id  = module.kms.key_id
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "LDAP_DC_version" {
  secret_id     = aws_secretsmanager_secret.LDAP_DC_secret.id
  secret_string = "dummy"
  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "Auth_Email_Account" {
  #checkov:skip=CKV2_AWS_57:doesn't need rotation
  name        = "${local.project_name}_Auth_Email_Account"
  description = "YJAF Preprod limited user account credentials. Account is used by Auth Service to call Conversion service to send non-YJAF users their temporary passcode."
  kms_key_id  = module.kms.key_id
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "Auth_Email_Account" {
  secret_id     = aws_secretsmanager_secret.Auth_Email_Account.id
  secret_string = "dummy" # InvalidRequestException: You must provide either SecretString or SecretBinary.
  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "Unit_test" {
  #checkov:skip=CKV2_AWS_57:doesn't need rotation
  name        = "${local.project_name}_Unit_test"
  description = "Used within Conversion configuration"
  kms_key_id  = module.kms.key_id
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "Unit_test" {
  secret_id     = aws_secretsmanager_secret.Unit_test.id
  secret_string = "dummy" # InvalidRequestException: You must provide either SecretString or SecretBinary.
  lifecycle {
    ignore_changes = [secret_string]
  }
}
