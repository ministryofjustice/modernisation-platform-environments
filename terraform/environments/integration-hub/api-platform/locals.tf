locals {
  api_configuration = try(local.application_data.accounts[local.environment].api_configuration, {})
  api_docs_configuration = merge(
    {
      basic_auth_username = "api-docs"
    },
    try(local.api_configuration.docs, {})
  )
  auth_configuration     = try(local.application_data.accounts[local.environment].auth_configuration, {})
  auth_roles             = try(local.auth_configuration.roles, {})
  auth_users             = try(local.auth_configuration.users, {})
  auth_system_principals = try(local.auth_configuration.system_principals, {})
  cors_allowed_origins   = try(local.api_configuration.cors_allowed_origins, [])
  transfer_clients       = try(local.application_data.accounts[local.environment].transfer_clients, {})
  multipart_configuration = merge(
    {
      single_put_limit_bytes            = 5368709120
      multipart_default_part_size_bytes = 67108864
      multipart_max_parts               = 10000
      multipart_initial_presign_parts   = 10
    },
    try(local.api_configuration.multipart_upload, {})
  )

  mft_upload_bucket_parameter_prefix = "/${local.application_name}/managed-file-transfer/${local.environment}/upload-bucket"
}
