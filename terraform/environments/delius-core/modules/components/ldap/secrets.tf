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
