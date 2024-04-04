module "nextcloud_efs" {
  for_each = toset(["html", "custom_apps", "config", "data", "themes"])

  source = "../../../../delius-core/modules/helpers/efs"

  name           = each.key
  env_name       = var.env_name
  creation_token = "${var.env_name}-${each.key}-efs"

  kms_key_arn                     = var.account_config.kms_keys.general_shared
  throughput_mode                 = "bursting"
  provisioned_throughput_in_mibps = null
  tags                            = var.tags

  vpc_id     = var.account_info.vpc_id
  subnet_ids = var.account_config.ordered_private_subnet_ids
  vpc_cidr   = var.account_config.shared_vpc_cidr
}
