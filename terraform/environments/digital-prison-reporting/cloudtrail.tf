resource "aws_cloudtrail" "trail" {
  #checkov:skip=CKV_AWS_251:Ensure CloudTrail logging is enabled
  #checkov:skip=CKV2_AWS_10: "Ignore - Ensure CloudTrail trails are integrated with CloudWatch Logs"
  count                         = local.enable_dpr_cloudtrail ? 1 : 0
  name                          = "${local.project}-cloud-trail-${local.environment}"
  s3_bucket_name                = module.s3_audit_logging_bucket.bucket_id
  s3_key_prefix                 = "cloud_trail"
  include_global_service_events = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }
  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-cloud-trail-${local.environment}"
      Resource_Type = "Cloud Trail"
      Jira          = "DPR-471"
    }
  )

  depends_on = [module.s3_audit_logging_bucket.bucket_id]
}