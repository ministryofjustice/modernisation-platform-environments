locals {
  delius_account_id  = var.platform_vars.environment_management.account_ids[join("-", ["delius-core", var.account_info.mp_environment])]
  oracle_port        = "1521"
  dms_audit_username = "delius_audit_dms_pool"
  dms_s3_local_bucket_prefix = "${var.env_name}-dms-destination-bucket"
  # dms_s3_local_bucket_secret = "dms-s3-local-bucket"
  # dms_s3_local_bucket_secret_access_role = "dms-s3-local-bucket-secret-access-role"
  dms_repository_account_id = nonsensitive(try(var.platform_vars.environment_management.account_ids[join("-", ["delius-core", var.dms_config.audit_target_endpoint.write_environment])],null))
  # The accounts which may write to the DMS S3 bucket are all Audit Clients of the current environment (if it is itself a Repository),
  # or the Audit Repository for the current environment (if it is itself a Client).
  dms_s3_writer_account_ids = compact(concat(var.dms_config.client_account_ids,[local.dms_repository_account_id]))
  # We define an S3 writer role for each Delius environment (rather than for the account)
  dms_s3_writer_role_name = "${var.env_name}-dms-s3-writer-role"
  
  dms_s3_writer_role_cross_account_arns = merge([for delius_account_name in var.delius_account_names : {
                                               for delius_environment_name in var.delius_environment_names : delius_environment_name => data.terraform_remote_state.get_dms_s3_bucket_info[delius_account_name].outputs.dms_s3_bucket_info.dms_s3_role_arn[delius_environment_name] if contains(local.dms_s3_writer_account_ids,try(regex("arn:aws:[^:]+:[^:]+:([0-9]+):.*",try(data.terraform_remote_state.get_dms_s3_bucket_info[delius_account_name].outputs.dms_s3_bucket_info.dms_s3_role_arn[delius_environment_name],"")),""))
                                            }
                                          ]...)
  
  dms_s3_repository_bucket = {
    prefix = try("${var.dms_config.audit_target_endpoint.write_environment}-dms-destination-bucket",null)
    # account_id = try(var.platform_vars.environment_management.account_ids[join("-", ["delius-core", var.dms_config.audit_target_endpoint.write_environment])],null)
  }

   dms_s3_bucket_info = {
       dms_s3_bucket_name = {(var.env_name) = module.s3_bucket_dms_destination.bucket.bucket}
       dms_s3_cross_account_bucket_names = local.dms_s3_cross_account_bucket_names
       dms_s3_role_arn = {(var.env_name) = aws_iam_role.dms_s3_writer_role.arn}
       dms_s3_cross_account_existing_roles = local.dms_s3_cross_account_existing_roles
       dms_s3_writer_role_cross_account_arns = local.dms_s3_writer_role_cross_account_arns
   }    
}