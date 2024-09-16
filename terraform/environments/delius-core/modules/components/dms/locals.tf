locals {
  account_id = data.aws_caller_identity.current.account_id
  delius_account_id = var.platform_vars.environment_management.account_ids[join("-", ["delius-core", var.account_info.mp_environment])]
  oracle_port = "1521"
  dms_audit_username = "delius_audit_dms_pool"
  # Although the S3 buckets are non-determininistic they will have a known prefix
  dms_s3_local_bucket_prefix = "${var.env_name}-dms-destination-bucket"

  # If we are reading from a standby database it will have an S1 or S2 suffix - strip this off to get the name of the primary database
  audit_source_primary = try(replace(upper(var.dms_config.audit_source_endpoint.read_database),"/S[1-2]$/",""),null)

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
  bucket_list_target_map = merge(local.repository_account_map, local.client_account_map)
  
  # dms_s3_writer_account_ids = flatten(compact(concat(local.client_account_ids,[local.dms_repository_account_id])))
  # We define an S3 writer role for each Delius environment (rather than for the account)
  dms_s3_writer_role_name = "${var.env_name}-dms-s3-writer-role"
  dms_s3_reader_role_name = "${var.env_name}-dms-s3-reader-role"
  dms_s3_lister_role_name = "${var.env_name}-dms-s3-lister-role"

  # bucket_json is the output of the Lambda function we use to list all of the buckets in the target AWS accounts.
  # The key is the delius_environment as we look up the list of buckets in all relevant environments:
  # 1. For clients we only look up the list of buckets in the associated repository environments.
  # 2. For repositories we look up the list of buckets in all of the associated client environments.
  bucket_json = {for k,v in data.http.get_buckets_lambda_output : k => jsondecode(v.response_body)}

  # We filter the bucket_json to only include buckets where the name matches the prefix used for DMS replication
  bucket_map = {
     for delius_environment, details in local.bucket_json :
     delius_environment => (
        length([for bucket in details.Buckets : bucket if try(regex(".*dms-destination-bucket.*", bucket),null) != null]) > 0 ?
        [for bucket in details.Buckets : bucket if try(regex(".*dms-destination-bucket.*", bucket),null) != null] : null
     )
  }

   s3_bucket_name_secret_arns = flatten([for k,v in data.aws_secretsmanager_secrets.dms_buckets : v.arns if v.arns != null])
}
