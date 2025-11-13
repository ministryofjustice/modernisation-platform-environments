# Role used by DE's to access AWS
data "aws_iam_roles" "modernisation_platform" {
  name_regex  = "AWSReservedSSO_modernisation-platform-developer_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

resource "aws_lakeformation_data_lake_settings" "lake_formation" {
  admins = [
    one(data.aws_iam_roles.modernisation_platform.arns),
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/MemberInfrastructureAccess"
  ]

  parameters = {
    "CROSS_ACCOUNT_VERSION" = "4"
  }
}

module "query_results" {
  source        = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"
  bucket_prefix = "property-query-results-${local.environment}-"

  custom_kms_key     = aws_kms_key.shared_kms_key.arn
  versioning_enabled = true
  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }

  tags = local.tags
}

module "datalake" {
  source        = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"
  bucket_prefix = "property-datalake-${local.environment}-"

  custom_kms_key     = aws_kms_key.shared_kms_key.arn
  versioning_enabled = true
  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }

  tags = local.tags
}
