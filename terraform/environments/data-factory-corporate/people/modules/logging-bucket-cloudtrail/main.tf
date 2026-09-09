module "log_bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=66bd5c6aa0d0396442f0d4a63642029ff38d2a8a"

  bucket_prefix      = var.bucket_prefix
  bucket_namespace   = "account-regional"
  versioning_enabled = true
  force_destroy      = false

  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false

  providers = {
    aws.bucket-replication = aws
  }

  sse_algorithm  = "aws:kms"
  custom_kms_key = var.kms_key_arn

  bucket_policy = [
    data.aws_iam_policy_document.cloudtrail_bucket.json
  ]

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${local.cloudtrail_name}"
  retention_in_days = var.cloudwatch_log_retention_in_days
  kms_key_id        = var.kms_key_arn

  tags = local.common_tags
}

resource "aws_sns_topic" "cloudtrail" {
  name              = "${local.cloudtrail_name}-notifications"
  kms_master_key_id = var.kms_key_arn

  tags = local.common_tags
}

resource "aws_cloudtrail" "sherlock" {
  name = local.cloudtrail_name

  s3_bucket_name = module.log_bucket.bucket.id
  kms_key_id     = var.kms_key_arn

  sns_topic_name = aws_sns_topic.cloudtrail.name

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn = aws_iam_role.cloudtrail_logs.arn

  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
}