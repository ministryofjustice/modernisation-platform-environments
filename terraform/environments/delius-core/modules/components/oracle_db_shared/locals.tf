locals {
  secret_prefix = "${var.env_name}-oracle"

  dba_secret_name = "${local.secret_prefix}-dba-passwords"

  application_secret_name = "${local.secret_prefix}-application-passwords"

  oem_account_id = var.platform_vars.environment_management.account_ids[join("-", ["hmpps-oem", var.account_info.mp_environment])]

  oracle_statistics_delius_target_account_id  = var.env_name == "dev" ? var.platform_vars.environment_management.account_ids["delius-core-test"] : var.env_name == "preprod" ? var.platform_vars.environment_management.account_ids["delius-core-production"] : ""
  oracle_statistics_delius_target_environment = var.env_name == "dev" ? "test" : var.env_name == "preprod" ? "prod" : var.env_name == "stage" ? "preprod" : ""
  oracle_statistics_delius_source_account_id  = var.env_name == "test" ? var.platform_vars.environment_management.account_ids["delius-core-development"] : var.env_name == "prod" ? var.platform_vars.environment_management.account_ids["delius-core-preproduction"] : ""
  oracle_statistics_delius_source_environment = var.env_name == "test" ? "dev" : var.env_name == "prod" ? "preprod" : ""

  oracle_duplicate_delius_target_account_id  = var.env_name == "dev" ? var.platform_vars.environment_management.account_ids["delius-core-test"] : var.env_name == "preprod" ? var.platform_vars.environment_management.account_ids["delius-core-production"] : ""
  oracle_duplicate_delius_target_environment = var.env_name == "dev" ? "test" : var.env_name == "preprod" ? "prod" : var.env_name == "stage" ? "preprod" : ""
  oracle_duplicate_delius_source_account_id  = var.env_name == "test" ? var.platform_vars.environment_management.account_ids["delius-core-development"] : var.env_name == "prod" ? var.platform_vars.environment_management.account_ids["delius-core-preproduction"] : ""
  oracle_duplicate_delius_source_environment = var.env_name == "test" ? "dev" : var.env_name == "prod" ? "preprod" : ""

  oracle_backup_bucket_prefix = "${var.account_info.mp_environment}-${var.env_name}-oracle-database-backups"
}
