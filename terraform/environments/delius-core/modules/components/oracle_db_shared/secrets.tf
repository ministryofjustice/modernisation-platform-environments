resource "aws_secretsmanager_secret" "delius_core_dba_passwords" {
  name        = join("-", [lookup(var.tags, "environment-name", null), lookup(var.tags, "delius-environment", null), replace(lookup(var.tags, "application", null), "-core", ""), "dba-passwords"])
  description = "DBA Users Credentials"
  kms_key_id  = var.account_config.kms_keys.general_shared
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "delius_core_dba_passwords" {
  secret_id     = aws_secretsmanager_secret.delius_core_dba_passwords.id
  secret_string = "REPLACE"
  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

resource "aws_secretsmanager_secret" "delius_core_application_passwords" {
  name        = join("-", [lookup(var.tags, "environment-name", null), lookup(var.tags, "delius-environment", null), replace(lookup(var.tags, "application", null), "-core", ""), "application-passwords"])
  description = "Application Users Credentials"
  kms_key_id  = var.account_config.kms_keys.general_shared
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "delius_core_application_passwords" {
  secret_id     = aws_secretsmanager_secret.delius_core_application_passwords.id
  secret_string = "REPLACE"
  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}
