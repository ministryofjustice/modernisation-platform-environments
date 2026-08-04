resource "aws_cloudtrail" "s3_data_events" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV2_AWS_10:CloudTrail logs are written to an encrypted S3 audit bucket for this data-event trail
  #checkov:skip=CKV_AWS_67:Trail is scoped to S3 data events for buckets in this account and region
  #checkov:skip=CKV_AWS_252:SNS notifications are not required for S3 data-event audit log delivery

  name                          = "${local.application_name}-${local.environment}-s3-data-events"
  s3_bucket_name                = module.s3_audit_bucket.s3_bucket_id
  s3_key_prefix                 = "s3-data-events"
  include_global_service_events = false
  is_multi_region_trail         = false
  enable_log_file_validation    = true
  kms_key_id                    = module.kms_s3_audit.key_arn

  event_selector {
    read_write_type           = "All"
    include_management_events = false

    data_resource {
      type   = "AWS::S3::Object"
      values = [for bucket in module.s3_bucket : "${bucket.s3_bucket_arn}/"]
    }
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-s3-data-events" }
  )

  depends_on = [module.s3_audit_bucket]
}