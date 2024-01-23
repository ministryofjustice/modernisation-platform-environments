module "efs" {
  source = "../../efs"

  name           = "ldap-efs-${var.env_name}"
  env_name       = var.env_name
  creation_token = "${var.env_name}-ldap"
  account_config = var.account_config
  ldap_config    = var.ldap_config
  account_info   = var.account_info

  kms_key_arn                     = var.account_config.general_shared_kms_key_arn
  throughput_mode                 = var.ldap_config.efs_throughput_mode
  provisioned_throughput_in_mibps = var.ldap_config.efs_provisioned_throughput
  tags                            = var.tags
}
