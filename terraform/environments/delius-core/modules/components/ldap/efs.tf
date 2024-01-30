module "efs" {
  source = "../../efs"

  name           = "ldap-efs-${var.env_name}"
  env_name       = var.env_name
  creation_token = "${var.env_name}-ldap"

  kms_key_arn                     = var.account_config.general_shared_kms_key_arn
  throughput_mode                 = var.ldap_config.efs_throughput_mode
  provisioned_throughput_in_mibps = var.ldap_config.efs_provisioned_throughput
  tags                            = var.tags

  vpc_id     = var.account_config.shared_vpc_id
  subnet_ids = var.account_config.private_subnet_ids
  vpc_cidr   = var.account_config.shared_vpc_cidr
}
