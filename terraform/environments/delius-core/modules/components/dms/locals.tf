locals {
  account_id = data.aws_caller_identity.current.account_id
  delius_account_id = var.platform_vars.environment_management.account_ids[join("-", ["delius-core", var.account_info.mp_environment])]
  oracle_port = "1521"
  dms_audit_username = "delius_audit_dms_pool"
  dms_s3_local_bucket_prefix = "${var.env_name}-dms-destination-bucket"
  # dms_s3_local_bucket_secret = "dms-s3-local-bucket"
  # dms_s3_local_bucket_secret_access_role = "dms-s3-local-bucket-secret-access-role"
  dms_repository_account_id = nonsensitive(try(var.platform_vars.environment_management.account_ids[join("-", ["delius-core", var.dms_config.audit_target_endpoint.write_environment])],null))
  # The accounts which may write to the DMS S3 bucket are all Audit Clients of the current environment (if it is itself a Repository),
  # or the Audit Repository for the current environment (if it is itself a Client).
  dms_s3_writer_account_ids = compact(concat(var.dms_config.client_account_ids,[local.dms_repository_account_id]))
  dms_s3_writer_role_name = "dms-s3-writer-role"
  dms_s3_repository_bucket = {
    prefix = try("${var.dms_config.audit_target_endpoint.write_environment}-dms-destination-bucket",null)
    # account_id = try(var.platform_vars.environment_management.account_ids[join("-", ["delius-core", var.dms_config.audit_target_endpoint.write_environment])],null)
  }
}