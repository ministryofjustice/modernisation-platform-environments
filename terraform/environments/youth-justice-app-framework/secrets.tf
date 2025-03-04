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
  secret_id = aws_secretsmanager_secret.auto_admit_secret.id
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
  secret_id = aws_secretsmanager_secret.LDAP_administration_secret.id
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
  secret_id = aws_secretsmanager_secret.LDAP_DC_secret.id
  lifecycle {
    ignore_changes = [secret_string]
  }
}
