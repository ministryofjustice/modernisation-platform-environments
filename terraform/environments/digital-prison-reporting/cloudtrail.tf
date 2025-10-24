resource "aws_cloudtrail" "trail" {
  #checkov:skip=CKV_AWS_251:Ensure CloudTrail logging is enabled
  #checkov:skip=CKV2_AWS_10: "Ignore - Ensure CloudTrail trails are integrated with CloudWatch Logs"
  #checkov:skip=CKV_AWS_36: "Ensure CloudTrail log file validation is enabled"
  #checkov:skip=CKV_AWS_67: "Ensure CloudTrail is enabled in all Regions"
  #checkov:skip=CKV_AWS_35: "Ensure CloudTrail logs are encrypted at rest using KMS CMKs"
  #checkov:skip=CKV_AWS_252: "Ensure CloudTrail defines an SNS Topic"

  count                         = local.enable_dpr_cloudtrail ? 1 : 0
  name                          = "${local.project}-cloud-trail-${local.environment}"
  s3_bucket_name                = module.s3_audit_logging_bucket.bucket_id
  s3_key_prefix                 = "cloud_trail"
  include_global_service_events = true
  enable_log_file_validation    = true

  kms_key_id = aws_kms_key.cloudtrail.key_id # Get KEY ID from Resource


  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }
  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-cloud-trail-${local.environment}"
      dpr-resource-type = "Cloud Trail"
      dpr-jira          = "DPR-471"
    }
  )

  depends_on = [module.s3_audit_logging_bucket.bucket_id]
}