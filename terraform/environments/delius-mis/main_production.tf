##
# Modules for each environment
# Separate per environment to allow different versions
##
module "environment_production" {

  source = "./modules/mis_environment"
  count  = local.is-production ? 1 : 0

  providers = {
    aws                       = aws
    aws.bucket-replication    = aws
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  env_name      = "prod"
  app_name      = local.application_name
  platform_vars = local.platform_vars

  account_config = local.account_config
  account_info   = local.account_info

  environment_config      = local.environment_config_production
  environments_in_account = local.delius_environments_per_account.prod

  bastion_config = local.bastion_config_production

  boe_efs_config = local.boe_efs_config_production

  bcs_config = local.bcs_config_production
  bps_config = local.bps_config_production
  bws_config = local.bws_config_production
  dis_config = local.dis_config_production
  dfi_config = local.dfi_config_production

  bcs_config_win = local.bcs_config_win_production

  dsd_db_config = local.dsd_db_config_production
  boe_db_config = local.boe_db_config_production
  mis_db_config = local.mis_db_config_production

  fsx_config               = local.fsx_config_production
  dfi_report_bucket_config = local.dfi_report_bucket_config_production
  lb_config                = local.lb_config_production
  datasync_config          = local.datasync_config_production

  pagerduty_integration_key = local.pagerduty_integration_key

  create_backup_role = true

  tags = local.tags

  db_backup_config = local.db_backup_config_production
}
