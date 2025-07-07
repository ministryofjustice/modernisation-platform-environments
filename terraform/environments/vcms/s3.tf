######################################
# General S3 bucket
######################################
module "general_bucket" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v8.2.1"

  bucket_prefix      = "${local.application_name}-${local.environment}"
  versioning_enabled = false

  providers = {
    aws.bucket-replication = aws
  }

  tags = local.tags
}
