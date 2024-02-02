locals {
  secret_prefix           = join("-", [lookup(var.tags, "environment-name", null), lookup(var.tags, "delius-environment", null), lookup(var.tags, "application", null)])
  dba_secret_name         = "${local.secret_prefix}-dba-passwords"
  application_secret_name = "${local.secret_prefix}-application-passwords"
  oem_account_id          = module.environment.cross_account_secret_account_ids.hmpps_oem
}