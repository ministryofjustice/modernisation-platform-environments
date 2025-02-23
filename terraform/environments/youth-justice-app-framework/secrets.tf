#### This file can be used to store secrets specific to the member account ####


resource "aws_secretsmanager_secret" "LDAP_DC_secret" {
  #checkov:skip=CKV2_AWS_57:doesn't need rotation
  name        = "LDAP-DC-Connection-String"
  description = "DC connection string for LDAP"
  kms_key_id  = module.kms.key_id
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "LDAP_DC_version" {
  secret_id     = aws_secretsmanager_secret.LDAP_DC_secret.id
  secret_string = "ldaps://IP-C613020B.i2n.com:636,ldaps://IP-C613015F.i2n.com:636,ldaps://IP-C613015B.i2n.com:636" #dummy values to be replaced later
  lifecycle {
    ignore_changes = [secret_string]
  }
}
