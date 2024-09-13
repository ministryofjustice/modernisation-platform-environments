locals {
  account_id = data.aws_caller_identity.current.account_id
  delius_account_id = var.platform_vars.environment_management.account_ids[join("-", ["delius-core", var.account_info.mp_environment])]
  oracle_port = "1521"
  dms_audit_username = "delius_audit_dms_pool"
  dms_s3_local_bucket_prefix = "${var.env_name}-dms-destination-bucket"

  # If we are reading from a standby database it will have an S1 or S2 suffix - strip this off to get the name of the primary database
  audit_source_primary = try(replace(upper(var.dms_config.audit_source_endpoint.read_database),"/S[1-2]$/",""),null)

  # dms_repository_account_id = nonsensitive(try(var.platform_vars.environment_management.account_ids[join("-", ["delius-core", var.dms_config.audit_target_endpoint.write_environment])],null))

  # Create map of repositories used by this environment (where this environment is a client)
  repository_account_map = try(var.dms_config.audit_target_endpoint.write_environment, null) == null ? {} : {(var.dms_config.audit_target_endpoint.write_environment) = var.env_name_to_dms_config_map[var.dms_config.audit_target_endpoint.write_environment].account_id} 

  # Create map of clients of this environment (where this environment is a repository)
  client_account_map = {for delius_environment in keys(var.env_name_to_dms_config_map):
      delius_environment => var.env_name_to_dms_config_map[delius_environment].account_id if try(var.env_name_to_dms_config_map[delius_environment].dms_config.audit_target_endpoint.write_environment,null) == var.env_name
  } 
  client_account_ids = values(local.client_account_map)
  
  # The bucket_list_target_map is, for this environment, either the repository account or all client accounts.
  # These will be mutually exclusive since a repository may not be a client. It provides a map
  # of all possible accounts for which we need to retrieve the S3 bucket names for DMS.
  bucket_list_target_map = merge(local.repository_account_map,local.client_account_map)
  
  # dms_s3_writer_account_ids = flatten(compact(concat(local.client_account_ids,[local.dms_repository_account_id])))
  # We define an S3 writer role for each Delius environment (rather than for the account)
  dms_s3_writer_role_name = "${var.env_name}-dms-s3-writer-role"
  dms_s3_reader_role_name = "${var.env_name}-dms-s3-reader-role"
  dms_s3_lister_role_name = "${var.env_name}-dms-s3-lister-role"

  # dms_s3_writer_role_cross_account_arns = merge([for delius_account_name in var.delius_account_names : {
  #                                              for delius_environment_name in var.delius_environment_names : delius_environment_name => data.terraform_remote_state.get_dms_s3_bucket_info[delius_account_name].outputs.dms_s3_bucket_info.dms_s3_role_arn[delius_environment_name] if contains(local.dms_s3_writer_account_ids,try(regex("arn:aws:iam::([0-9]+):.*",try(data.terraform_remote_state.get_dms_s3_bucket_info[delius_account_name].outputs.dms_s3_bucket_info.dms_s3_role_arn[delius_environment_name],""))[0],""))
  #                                           }
  #                                         ]...)

  # dms_s3_repository_bucket = {
  #   prefix = try("${var.dms_config.audit_target_endpoint.write_environment}-dms-destination-bucket",null)
  #   # account_id = try(var.platform_vars.environment_management.account_ids[join("-", ["delius-core", var.dms_config.audit_target_endpoint.write_environment])],null)
  # }

  # bucket_json = try(jsondecode(data.http.get_buckets_lambda_output[0].response_body),jsondecode("{}"))

  bucket_json = {for k,v in data.http.get_buckets_lambda_output : k => jsondecode(v.response_body)}

  bucket_map = {
     for delius_environment, details in local.bucket_json :
     delius_environment => (
        length([for bucket in details.Buckets : bucket if try(regex(".*dms-destination-bucket.*", bucket),null) != null]) > 0 ?
        [for bucket in details.Buckets : bucket if try(regex(".*dms-destination-bucket.*", bucket),null) != null] : null
     )
  }

  # repository_bucket_name = try([
  #   for bucket in local.repository_bucket_json.Buckets : 
  #       bucket if try(regex(".*dms-destination-bucket.*", bucket),null) != null
  # ],[])

   dms_s3_bucket_info = {
       dms_s3_bucket_name = {(var.env_name) = module.s3_bucket_dms_destination.bucket.bucket}
       dms_s3_bucket_arn = {(var.env_name) = module.s3_bucket_dms_destination.bucket.arn}
       # dms_s3_cross_account_bucket_names = local.dms_s3_cross_account_bucket_names
       # dms_s3_cross_account_bucket_arns = local.dms_s3_cross_account_bucket_arns
       dms_s3_role_arn = {(var.env_name) = aws_iam_role.dms_s3_writer_role.arn}
       # dms_s3_cross_account_existing_roles = local.dms_s3_cross_account_existing_roles
       # dms_s3_writer_role_cross_account_arns = local.dms_s3_writer_role_cross_account_arns
       # dms_s3_writer_account_ids = local.dms_s3_writer_account_ids
       dms_s3_repository_environment = {(var.env_name) = try(var.dms_config.audit_target_endpoint.write_environment,null)}
       # dms_s3_cross_account_repository_environments = local.dms_s3_cross_account_repository_environments
       #dms_s3_cross_account_client_environments = local.dms_s3_cross_account_client_environments
       # dms_s3_audit_source_primary_database = {(var.env_name) = local.audit_source_primary}
       # dms_s3_cross_account_audit_source_databases = local.dms_s3_cross_account_audit_source_databases
       client_account_ids = local.client_account_ids
       client_account_map = local.client_account_map
       bucket_json = local.bucket_json
       bucket_map = local.bucket_map
   }    
}