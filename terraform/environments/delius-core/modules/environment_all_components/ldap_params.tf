
resource "aws_secretsmanager_secret" "delius_core_ldap_credential" {
  name = "${var.account_info.application_name}-${var.env_name}-openldap-bind-password"
}

resource "aws_secretsmanager_secret_version" "delius_core_ldap_credential" {
  secret_id     = aws_secretsmanager_secret.delius_core_ldap_credential.id
  secret_string = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

data "aws_secretsmanager_secret" "delius_core_ldap_credential" {
  name = aws_secretsmanager_secret.delius_core_ldap_credential.name
}

resource "aws_secretsmanager_secret" "delius_core_ldap_seed_uri" {
  name = "${var.account_info.application_name}-${var.env_name}-openldap-seed-uri"
}

resource "aws_secretsmanager_secret_version" "delius_core_ldap_seed_uri" {
  secret_id     = aws_secretsmanager_secret.delius_core_ldap_seed_uri.id
  secret_string = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

####################
# LDAP HOST
####################

resource "aws_ssm_parameter" "delius_core_ldap_host" {
  name  = format("/%s-%s/LDAP_HOST", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags
}

####################
# LDAP PRINCIPAL
####################

resource "aws_ssm_parameter" "delius_core_ldap_principal" {
  name  = format("/%s-%s/LDAP_PRINCIPAL", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags
}

####################
# LDAP SEED URI
####################

resource "aws_ssm_parameter" "delius_core_ldap_seed_uri" {
  name  = format("/%s-%s/LDAP_SEED_URI", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags
}

####################
# LDAP CREDENTIAL
####################

resource "aws_ssm_parameter" "delius_core_ldap_credential" {
  name  = format("/%s-%s/LDAP_CREDENTIAL", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags
}
