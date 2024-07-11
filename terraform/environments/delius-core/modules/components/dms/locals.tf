locals {
  secret_prefix = "${var.account_info.application_name}-${var.env_name}-oracle-${var.db_suffix}"
  dms_audit_source_endpoint_secret_name = "${local.secret_prefix}-dms-audit-source-endpoint-db"
  dms_user_source_endpoint_secret_name = "${local.secret_prefix}-dms-user-source-endpoint-db"
  delius_account_id = var.platform_vars.environment_management.account_ids[join("-", ["delius-core", var.account_info.mp_environment])]
  oracle_port = "1521"
  dms_audit_username = "delius_audit_dms_pool"
}