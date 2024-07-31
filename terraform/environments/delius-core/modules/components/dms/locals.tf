locals {
  delius_account_id  = var.platform_vars.environment_management.account_ids[join("-", ["delius-core", var.account_info.mp_environment])]
  oracle_port        = "1521"
  dms_audit_username = "delius_audit_dms_pool"
  dms_s3_local_bucket_prefix = "${var.env_name}-dms-destination-bucket"
  dms_s3_local_bucket_secret = "dms-s3-local-bucket"
  dms_s3_local_bucket_secret_access_role = "dms-s3-local-bucket-secret-access-role"
  dms_repository_account_id = nonsensitive(try(var.platform_vars.environment_management.account_ids[join("-", ["delius-core", var.dms_config.audit_target_endpoint.write_environment])],null))
  dms_s3_repository_bucket = {
    prefix = try("${var.dms_config.audit_target_endpoint.write_environment}-dms-destination-bucket",null)
    # account_id = try(var.platform_vars.environment_management.account_ids[join("-", ["delius-core", var.dms_config.audit_target_endpoint.write_environment])],null)
  }
}