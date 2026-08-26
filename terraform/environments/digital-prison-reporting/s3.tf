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
      dpr-name          = "${local.project}-audit-logging-${local.environment}"
      dpr-resource-type = "S3 Bucket"
      dpr-jira          = "DPR-471"
    }
  )
}

# S3 Transfer Bucket, DPR-504
module "s3_transfer_artifacts_bucket" {
  source                    = "./modules/s3_bucket"
  create_s3                 = local.setup_buckets
  name                      = "${local.project}-transfer-artifacts-${local.environment}"
  custom_kms_key            = local.s3_kms_arn
  create_notification_queue = false # For SQS Queue
  enable_lifecycle          = true
  cloudtrail_access_policy  = true

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-transfer-artifacts-${local.environment}"
      dpr-resource-type = "S3 Bucket"
      dpr-jira          = "DPR-504"
    }
  )
}

# S3 Domain Preview Bucket, DPR-637
module "s3_domain_preview_bucket" {
  source                    = "./modules/s3_bucket"
  create_s3                 = local.setup_buckets
  name                      = "${local.project}-domain-preview-${local.environment}"
  custom_kms_key            = local.s3_kms_arn
  create_notification_queue = false # For SQS Queue
  enable_lifecycle          = true
  cloudtrail_access_policy  = true

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-domain-preview-${local.environment}"
      dpr-resource-type = "S3 Bucket"
      dpr-jira          = "DPR-637"
    }
  )
}

# S3 Structured Historical, DPR2-717
module "s3_structured_historical_bucket" {
  source                    = "./modules/s3_bucket"
  create_s3                 = local.setup_buckets
  name                      = "${local.project}-structured-historical-${local.environment}"
  custom_kms_key            = local.s3_kms_arn
  create_notification_queue = false
  enable_lifecycle          = true
  cloudtrail_access_policy  = true

  tags = merge(
    local.all_tags,
    {
      dpr-name          = "${local.project}-structured-historical-${local.environment}"
      dpr-resource-type = "S3 Bucket"
      dpr-jira          = "DPR2-717"
    }
  )
}
