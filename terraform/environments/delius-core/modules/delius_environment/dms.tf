module "dms" {
  source                      = "../components/dms"
  account_config              = var.account_config
  account_info                = var.account_info
  tags                        = var.tags
  env_name                    = var.env_name
  platform_vars               = var.platform_vars
  dms_config                  = var.dms_config

  delius_core_application_passwords_arn = module.oracle_db_shared.delius_core_application_passwords_arn
  oracle_db_server_names                = local.oracle_db_server_names
  dms_audit_endpoint_client_config      = var.dms_audit_endpoint_client_config
  dms_audit_endpoint_repository_config  = var.dms_audit_endpoint_repository_config

  providers = {
    aws                       = aws
    aws.bucket-replication    = aws
    aws.core-vpc              = aws
    aws.core-network-services = aws
  }
}

locals {
  oracle_db_server_names = {
     primarydb = module.oracle_db_primary[0].oracle_db_server_name,
     standbydb1 = try(module.oracle_db_standby[0].oracle_db_server_name,"none"),
     standbydb2 = try(module.oracle_db_standby[1].oracle_db_server_name,"none")
  }

}