module "efs" {
  source = "../../helpers/efs"

  name           = "ldap"
  env_name       = var.env_name
  creation_token = "${var.env_name}-ldap"

  kms_key_arn                     = var.account_config.kms_keys.general_shared
  throughput_mode                 = var.ldap_config.efs_throughput_mode
  provisioned_throughput_in_mibps = var.ldap_config.efs_provisioned_throughput
  tags                            = var.tags
  enable_platform_backups         = var.enable_platform_backups

  vpc_id       = var.account_config.shared_vpc_id
  subnet_ids   = var.account_config.private_subnet_ids
  vpc_cidr     = var.account_config.shared_vpc_cidr
  account_info = var.account_info
}
