module "ldap" {

  source = "../components/ldap"

  providers = {
    aws                       = aws
    aws.bucket-replication    = aws
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  env_name           = var.env_name
  app_name           = "ldap"
  account_config     = var.account_config
  account_info       = var.account_info
  environment_config = var.environment_config
  ldap_config        = var.ldap_config

  bastion_sg_id = module.bastion_linux.bastion_security_group

  platform_vars           = var.platform_vars
  tags                    = local.tags
  enable_platform_backups = var.enable_platform_backups
}
