locals {
  secret_prefix           = join("-", [lookup(var.tags, "environment-name", null), lookup(var.tags, "delius-environment", null), lookup(var.tags, "application", null)])
  dba_secret_name         = "${local.secret_prefix}-dba-passwords"
  application_secret_name = "${local.secret_prefix}-application-passwords"
  oem_account_id          = var.platform_vars.environment_management.account_ids[join("-", ["hmpps-oem", var.account_info.mp_environment])]
  oracle_statistics_delius_target_account_id  = var.env_name == "dev" ? var.platform_vars.environment_management.account_ids["delius-core-test"] : var.env_name == "preprod" ? var.platform_vars.environment_management.account_ids["delius-core-production"] : ""
  oracle_statistics_delius_target_environment = var.env_name == "dev" ? "test" : var.env_name == "preprod" ? "prod" : var.env_name == "stage" ? "preprod" : ""
  oracle_statistics_delius_source_account_id  = var.env_name == "test" ? var.platform_vars.environment_management.account_ids["delius-core-development"] : var.env_name == "prod" ? var.platform_vars.environment_management.account_ids["delius-core-preproduction"] : ""
  oracle_statistics_delius_source_environment = var.env_name == "test" ? "dev" : var.env_name == "prod" ? "preprod" : ""
}