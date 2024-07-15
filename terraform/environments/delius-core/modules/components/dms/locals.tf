locals {
  delius_account_id  = var.platform_vars.environment_management.account_ids[join("-", ["delius-core", var.account_info.mp_environment])]
  oracle_port        = "1521"
  dms_audit_username = "delius_audit_dms_pool"
}