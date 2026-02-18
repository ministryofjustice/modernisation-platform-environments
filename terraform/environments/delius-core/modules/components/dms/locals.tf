locals {
  db_port            = 1521
  dms_audit_username = "delius_audit_dms_pool"

  # Although it is recommended to use bucket_prefix rather than bucket_name when creating an S3 bucket
  # using the modernisation-platform-terraform-s3-bucket repo, this introduces significant complications
  # in this use case since we need to know the names of the buckets in other accounts, and having
  # a random suffix makes this difficult to acheive without a lot of extra code.  Therefore in this
  # special case we go against the recommendation and use a fixed name for the bucket in each environment
  # so that it can be templated and does not need to be looked up.
  dms_s3_local_bucket_format = "delius-audit-dms-s3-staging-bucket"
  dms_s3_local_bucket_name   = "${var.env_name}-${local.dms_s3_local_bucket_format}"

  # If we are reading from a standby database it will have an S1 or S2 suffix - strip this off to get the name of the primary database
  audit_source_primary = try(replace(upper(var.dms_config.audit_source_endpoint.read_database), "/S[1-2]$/", ""), null)

  # Create map of repositories used by this environment (where this environment is a client)
  repository_account_map = try(var.dms_config.audit_target_endpoint.write_environment, null) == null ? {} : { (var.dms_config.audit_target_endpoint.write_environment) = var.env_name_to_dms_config_map[var.dms_config.audit_target_endpoint.write_environment].account_id }

  # Create map of clients of this environment (where this environment is a repository)
  client_account_map = { for delius_environment in keys(var.env_name_to_dms_config_map) :
    delius_environment => var.env_name_to_dms_config_map[delius_environment].account_id if try(var.env_name_to_dms_config_map[delius_environment].dms_config.audit_target_endpoint.write_environment, null) == var.env_name
  }

  # The bucket_list_target_map is, for this environment, either the repository account or all client accounts.
  # These will be mutually exclusive since a repository may not be a client. It provides a map
  # of all possible accounts for which we need to retrieve the S3 bucket names for DMS.
  bucket_list_target_map = merge(local.repository_account_map, local.client_account_map)

  bucket_map = {
    for delius_environment in keys(local.bucket_list_target_map) :
    delius_environment => "${delius_environment}-${local.dms_s3_local_bucket_format}"
  }

  # dms_s3_writer_account_ids = flatten(compact(concat(local.client_account_ids,[local.dms_repository_account_id])))
  # We define an S3 writer role for each Delius environment (rather than for the account)
  dms_s3_writer_role_name = "${var.env_name}-dms-s3-writer-role"
  dms_s3_reader_role_name = "${var.env_name}-dms-s3-reader-role"
}