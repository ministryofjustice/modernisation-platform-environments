# The User s3 source endpoint is only required in Client environments
resource "aws_dms_s3_endpoint" "dms_user_source_endpoint_s3" {
   count                           = try(var.dms_config.user_target_endpoint.write_database, null) == null ? 0 : 1
   endpoint_id                     = "s3-staging-of-user-data-from-${var.dms_config.audit_target_endpoint.write_environment}"
   endpoint_type                   = "source"
   service_access_role_arn         = aws_iam_role.dms_s3_reader_role.arn
   bucket_name                     = module.s3_bucket_dms_destination.bucket.bucket
   bucket_folder                   = "user"
   cdc_path                        = "cdc"
   external_table_definition       = file("files/user_external_table_definition.json")
   timestamp_column_name           = "TIMESTAMP"
}

# The Audit s3 source endpoint is only required in Repository environments.
# One endpoint is required for each of the clients of that repository.
resource "aws_dms_s3_endpoint" "dms_audit_source_endpoint_s3" {
   for_each                        = toset(try(local.dms_s3_cross_account_client_environments[var.env_name],[]))
   endpoint_id                     = "s3-staging-of-audit-data-from-${each.value}"
   endpoint_type                   = "source"
   service_access_role_arn         = aws_iam_role.dms_s3_reader_role.arn
   bucket_name                     = module.s3_bucket_dms_destination.bucket.bucket
   bucket_folder                   = "audit/${local.dms_s3_cross_account_audit_source_databases[each.value]}"
   cdc_path                        = "cdc"
   external_table_definition       = file("files/audit_external_table_definition.json")
   timestamp_column_name           = "TIMESTAMP"
}