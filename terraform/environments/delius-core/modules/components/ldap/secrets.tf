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
# LDAP BIND PASSWORD
####################

resource "aws_ssm_parameter" "delius_core_ldap_bind_password" {
  name  = format("/%s-%s/LDAP_BIND_PASSWORD", var.account_info.application_name, var.env_name)
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
# LDAP ADMIN PASSWORD
####################

module "ldap_admin_password" {
  source              = "../../helpers/secret"
  name                = "ldap-admin-password-${var.env_name}"
  description         = "LDAP Admin Password"
  tags                = var.tags
  kms_key_id          = var.account_config.kms_keys.general_shared
  allowed_account_ids = [var.platform_vars.environment_management.account_ids[join("-", ["delius-nextcloud", var.account_info.mp_environment])]]
}

####################
# LDAP RBAC VERSION
####################

resource "aws_ssm_parameter" "delius_core_ldap_rbac_version" {
  name  = format("/%s-%s/LDAP_RBAC_VERSION", var.account_info.application_name, var.env_name)
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = var.tags
}