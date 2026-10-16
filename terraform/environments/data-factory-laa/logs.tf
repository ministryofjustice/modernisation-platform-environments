locals {
  access_log_destination = {
    log_bucket_name = module.access_logs.bucket.id
    log_bucket_arn  = module.access_logs.bucket.arn
  }

  access_log_source_arns = concat(
    [for bucket in module.data_lake_buckets : bucket.bucket.arn],
    [module.s3-bucket.bucket.arn],
    [for bucket in module.fabric_curated_bucket : bucket.bucket.arn],
    [for bucket in module.data_claims_mapping_bucket : bucket.bucket.arn],
    flatten([for ingestion in module.file_ingestion : ingestion.access_log_source_arns])
  )
}

module "access_logs" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=0294b1a1303028f91707fdc67f1e4bba63d34ea6"

  bucket_prefix       = "access-logs"
  bucket_namespace    = "account-regional"
  versioning_enabled  = true
  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false
  # S3 server access logging destinations must use SSE-S3.
  sse_algorithm = "AES256"

  bucket_policy_v2 = [{
    effect  = "Allow"
    actions = ["s3:PutObject"]
    principals = {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    conditions = [
      {
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values   = local.access_log_source_arns
      },
      {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
    ]
  }]

  providers = {
    aws.bucket-replication = aws
  }

  tags = local.tags
}
