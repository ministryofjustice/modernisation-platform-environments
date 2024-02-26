locals {
  secret_prefix           = join("-", [lookup(var.tags, "environment-name", null), lookup(var.tags, "delius-environment", null), lookup(var.tags, "application", null)])
  dba_secret_name         = "${local.secret_prefix}-dba-passwords"
  application_secret_name = "${local.secret_prefix}-application-passwords"
  oem_account_id          = var.platform_vars.environment_management.account_ids[join("-", ["hmpps-oem", var.account_info.mp_environment])]
  legacy_s3_bucket_env    = var.env_name == "dev" ? "dmd-mis-dev" : var.env_name == "test" ? "del-test" : var.env_name == "training" ? "dt-training" : null
  legacy_s3_bucket        = local.legacy_s3_bucket_env != null ? "eu-west-2-${local.legacy_s3_bucket_env}-oracledb-backups" : null
}