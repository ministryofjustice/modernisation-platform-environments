####################
# LDAP ADMIN PASSWORD
####################

module "ldap_admin_password" {
  source              = "../../helpers/secret"
  name                = "ldap-admin-password-${var.env_name}"
  description         = "LDAP Admin Password"
  tags                = var.tags
  kms_key_id          = var.account_config.kms_keys.general_shared
}
