######################################
# S3 Bucket for ssm session manager
######################################
module "s3_bucket_ssm_sessions" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v8.2.1"

  bucket_prefix      = "${var.account_info.application_name}-${var.env_name}-ssm-sessions"
  versioning_enabled = false

  providers = {
    aws.bucket-replication = aws
  }

  tags = var.tags
}
