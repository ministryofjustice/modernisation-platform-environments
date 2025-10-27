module "dms" {
  count          = var.dms_config.deploy_dms ? 1 : 0
  source         = "../components/dms"
  account_config = var.account_config
  account_info   = var.account_info
  tags           = var.tags
  env_name       = var.env_name
  platform_vars  = var.platform_vars
  dms_config     = var.dms_config

  database_application_passwords_secret_arn = module.oracle_db_shared.database_application_passwords_secret_arn
  oracle_db_server_names                    = local.oracle_db_server_names
  db_ec2_sg_id                              = module.oracle_db_shared.db_ec2_sg_id
  env_name_to_dms_config_map                = var.env_name_to_dms_config_map

  providers = {
    aws                        = aws
    aws.bucket-replication     = aws
    aws.core-vpc               = aws
    aws.core-network-services  = aws
    aws.modernisation-platform = aws.modernisation-platform
  }
}
