##
# Modules for each environment
# Separate per environment to allow different versions
##
module "environment_dev" {
  # We're in dev account and dev environment, could reference different version
  source = "./modules/mis_environment"
  count  = local.is-development ? 1 : 0

  providers = {
    aws                       = aws
    aws.bucket-replication    = aws
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  env_name      = "dev"
  app_name      = local.application_name
  platform_vars = local.platform_vars

  account_config = local.account_config
  account_info   = local.account_info

  environment_config      = local.environment_config_dev
  environments_in_account = local.delius_environments_per_account.dev

  bastion_config = local.bastion_config_dev

  boe_efs_config = local.boe_efs_config_dev

  bcs_config  = local.bcs_config_dev
  bps_config  = local.bps_config_dev
  bws_config  = local.bws_config_dev
  dis_config  = local.dis_config_dev
  auto_config = local.auto_config_dev
  dfi_config  = local.dfi_config_dev

  dsd_db_config = local.dsd_db_config_dev
  boe_db_config = local.boe_db_config_dev
  mis_db_config = local.mis_db_config_dev

  fsx_config               = local.fsx_config_dev
  dfi_report_bucket_config = local.dfi_report_bucket_config
  lb_config                = local.lb_config
  datasync_config          = local.datasync_config_dev

  domain_join_ports = local.domain_join_ports

  pagerduty_integration_key = local.pagerduty_integration_key

  create_backup_role = true

  tags = local.tags
}
