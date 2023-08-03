
resource "aws_secretsmanager_secret" "delius_core_ldap_credential" {
  name = "${var.account_info.application_name}-${var.env_name}-openldap-bind-password"
}

resource "aws_secretsmanager_secret" "delius_core_ldap_principal" {
  name = "${var.account_info.application_name}-${var.env_name}-openldap-root-principal"
}

data "aws_secretsmanager_secret" "delius_core_ldap_credential" {
  name = aws_secretsmanager_secret.delius_core_ldap_credential.name
}

data "aws_ssm_parameter" "delius_core_ldap_principal" {
  name = aws_ssm_parameter.delius_core_ldap_principal.name
}

resource "aws_ssm_parameter" "delius_core_ldap_host" {
  name  = format("/%s/%s/LDAP_HOST", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags
}

