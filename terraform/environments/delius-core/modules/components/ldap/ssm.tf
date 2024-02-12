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
  tags = var.tags
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
  tags = var.tags
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
  tags = var.tags
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
  tags = var.tags
}
