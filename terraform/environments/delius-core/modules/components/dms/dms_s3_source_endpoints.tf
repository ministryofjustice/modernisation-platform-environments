# The User s3 source endpoint is only required in Client environments
resource "aws_dms_s3_endpoint" "dms_user_source_endpoint_s3" {
   count                           = try(var.dms_config.user_target_endpoint.write_database, null) == null ? 0 : 1
   endpoint_id                     = "s3-staging-of-user-data-from-${var.dms_config.audit_target_endpoint.write_environment}"
   endpoint_type                   = "source"
   service_access_role_arn         = aws_iam_role.dms_s3_reader_role.arn
   bucket_name                     = module.s3_bucket_dms_destination.bucket.bucket
   bucket_folder                   = "user"
}
