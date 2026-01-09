##
# Modules for each environment
# Separate per environment to allow different versions
##
module "environment_stage" {

  source = "./modules/mis_environment"
  count  = local.is-preproduction ? 1 : 0

  providers = {
    aws                       = aws
    aws.bucket-replication    = aws
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  env_name      = "stage"
  app_name      = local.application_name
  platform_vars = local.platform_vars

  account_config = local.account_config
  account_info   = local.account_info

  environment_config      = local.environment_config_stage
  environments_in_account = local.delius_environments_per_account.preprod

  bastion_config = local.bastion_config_stage

  bcs_config = local.bcs_config_stage
  bps_config = local.bps_config_stage
  bws_config = local.bws_config_stage
  dis_config = local.dis_config_stage
  dfi_config = local.dfi_config_stage

  dsd_db_config = local.dsd_db_config_stage
  boe_db_config = local.boe_db_config_stage
  mis_db_config = local.mis_db_config_stage

  fsx_config               = local.fsx_config_stage
  dfi_report_bucket_config = local.dfi_report_bucket_config_stage
  lb_config                = local.lb_config_stage

  pagerduty_integration_key = local.pagerduty_integration_key

  create_backup_role = true

  tags = local.tags
}


module "environment_preproduction" {

  source = "./modules/mis_environment"
  count  = local.is-preproduction ? 1 : 0

  providers = {
    aws                       = aws
    aws.bucket-replication    = aws
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  env_name      = "preprod"
  app_name      = local.application_name
  platform_vars = local.platform_vars

  account_config = local.account_config
  account_info   = local.account_info

  environment_config      = local.environment_config_preprod
  environments_in_account = local.delius_environments_per_account.preprod

  bastion_config = local.bastion_config_preprod

  bcs_config = local.bcs_config_preprod
  bps_config = local.bps_config_preprod
  bws_config = local.bws_config_preprod
  dis_config = local.dis_config_preprod
  dfi_config = local.dfi_config_preprod

  dsd_db_config = local.dsd_db_config_preprod
  boe_db_config = local.boe_db_config_preprod
  mis_db_config = local.mis_db_config_preprod

  fsx_config               = local.fsx_config_preprod
  dfi_report_bucket_config = local.dfi_report_bucket_config_preprod
  lb_config                = local.lb_config_preprod

  pagerduty_integration_key = local.pagerduty_integration_key

  create_backup_role = false

  tags = local.tags
}
