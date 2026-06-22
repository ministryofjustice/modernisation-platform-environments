# S3 bucket using MP module v10.0.0 - https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket
module "s3-bucket-files" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v10.0.0"

  bucket_prefix      = "${local.application_name_short}-${local.environment}-filesync-"
  versioning_enabled = false

  ownership_controls = "BucketOwnerEnforced"

  providers = {
    aws.bucket-replication = aws
  }

  sse_algorithm      = "aws:kms"
  custom_kms_key     = data.aws_kms_key.general_shared.arn

  tags = local.tags
}
