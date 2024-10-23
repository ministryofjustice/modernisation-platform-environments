# The User s3 source endpoint is only required in Client environments
resource "aws_dms_s3_endpoint" "dms_user_source_endpoint_s3" {
  #checkov:skip=CKV_AWS_298
  count                     = try(var.dms_config.user_target_endpoint.write_database, null) == null ? 0 : 1
  endpoint_id               = "${var.env_name}-s3-staging-of-user-data-from-${var.dms_config.audit_target_endpoint.write_environment}"
  endpoint_type             = "source"
  service_access_role_arn   = aws_iam_role.dms_s3_reader_role.arn
  bucket_name               = module.s3_bucket_dms_destination.bucket.bucket
  bucket_folder             = "user"
  cdc_path                  = "cdc"
  external_table_definition = file("files/user_external_table_definition.json")
  timestamp_column_name     = "TIMESTAMP"
}

# The Audit s3 source endpoint is only required in Repository environments.
# We name the bucket folder after the write database for the client, since this must always be the name of the client's primary database.
# One endpoint is required for each of the clients of that repository.
resource "aws_dms_s3_endpoint" "dms_audit_source_endpoint_s3" {
  #checkov:skip=CKV_AWS_298
  for_each                  = local.client_account_map
  endpoint_id               = "${var.env_name}-s3-staging-of-audit-data-from-${each.key}"
  endpoint_type             = "source"
  service_access_role_arn   = aws_iam_role.dms_s3_reader_role.arn
  bucket_name               = module.s3_bucket_dms_destination.bucket.bucket
  bucket_folder             = "audit/${var.env_name_to_dms_config_map[each.key].dms_config.user_target_endpoint.write_database}"
  cdc_path                  = "cdc"
  external_table_definition = file("files/audit_external_table_definition.json")
  timestamp_column_name     = "TIMESTAMP"
}