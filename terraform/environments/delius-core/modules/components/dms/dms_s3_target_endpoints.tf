# We must have both a source and target endpoint for each environment involved in Audit Preservation
# since there is a flow of Audit data in one directory and User data in the other direction (since
# user IDs must be kept consistent)

# In client environments the dms_audit_source_endpoint.read_database must be defined
# The endpoint for audit (AUDITED_INTERACTION) is the Delius database.
resource "aws_dms_s3_endpoint" "dms_audit_target_endpoint_s3" {
  #checkov:skip=CKV_AWS_298
  count                   = length(local.repository_account_map)
  endpoint_id             = "${var.env_name}-s3-staging-of-audit-data-from-${lower(var.dms_config.audit_source_endpoint.read_database)}"
  endpoint_type           = "target"
  service_access_role_arn = aws_iam_role.dms_s3_writer_role.arn
  bucket_name             = local.bucket_map[var.dms_config.audit_target_endpoint.write_environment]
  bucket_folder           = "audit/${local.audit_source_primary}"
  cdc_path                = "cdc"
  preserve_transactions   = true
  timestamp_column_name   = "TIMESTAMP"
  canned_acl_for_objects  = "bucket-owner-full-control"
}

# In repository environments we must loop through all client environments which write to it, as we
# will be pushing user updates to all of these.
resource "aws_dms_s3_endpoint" "dms_user_target_endpoint_s3" {
  #checkov:skip=CKV_AWS_298
  for_each                = local.client_account_map
  endpoint_id             = "${var.env_name}-s3-staging-of-user-data-from-${lower(var.dms_config.user_source_endpoint.read_database)}-to-${each.key}"
  endpoint_type           = "target"
  service_access_role_arn = aws_iam_role.dms_s3_writer_role.arn
  bucket_name             = local.bucket_map[each.key]
  bucket_folder           = "user"
  cdc_path                = "cdc"
  preserve_transactions   = true
  timestamp_column_name   = "TIMESTAMP"
  canned_acl_for_objects  = "bucket-owner-full-control"
}
