# S3 Logging Bucket, DPR-471
module "s3_audit_logging_bucket" {
  source                    = "./modules/s3_bucket"
  create_s3                 = local.setup_buckets
  name                      = "${local.project}-audit-logging-${local.environment}"
  custom_kms_key            = local.s3_kms_arn
  create_notification_queue = false # For SQS Queue
  enable_lifecycle          = true
  cloudtrail_access_policy  = true

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-audit-logging-${local.environment}"
      Resource_Type = "S3 Bucket"
      Jira          = "DPR-471"
    }
  )
}