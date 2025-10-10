resource "aws_lakeformation_data_lake_settings" "lake_formation" {
  admins = []

  parameters = {
    "CROSS_ACCOUNT_VERSION" = "4"
  }
}

module "lakeformation_bucket" {
  source        = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"
  bucket_prefix = "lakeformation-datalake-"

  custom_kms_key     = aws_kms_key.shared_kms_key.arn
  versioning_enabled = true

  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }
  tags = local.tags
}
