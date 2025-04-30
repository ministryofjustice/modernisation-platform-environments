module "s3_bucket_db_uplift" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v8.2.1"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_name = "${var.app_name}-${var.env_name}-db-uplift"

  tags = local.tags
}
