locals {
  secret_prefix = "${var.account_info.application_name}-${var.env_name}-oracle-${var.db_suffix}"
  dms_audit_endpoint_source_secret_name = "${local.secret_prefix}-dms-audit-endpoint-source"
  dms_asm_endpoint_source_secret_name = "${local.secret_prefix}-dms-asm-endpoint-source"
  dms_audit_endpoint_target_secret_name = "${local.secret_prefix}-dms-audit-endpoint-target"

  delius_account_id = var.platform_vars.environment_management.account_ids[join("-", ["delius-core", var.account_info.mp_environment])]

}