resource "aws_lakeformation_data_lake_settings" "lake_formation" {
  admins = [
    "arn:aws:iam::931816152367:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_modernisation-platform-developer_4606117482437e94",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/MemberInfrastructureAccess"
  ]

  parameters = {
    "CROSS_ACCOUNT_VERSION" = "4"
  }
}

// KMS key for encrypting S3 bucket objects and Lake Formation
resource "aws_kms_key" "data_kms_key" {
  description             = "KMS key for encrypting Data Lake resources"
  deletion_window_in_days = 30

  tags = local.tags
}

module "lakeformation_bucket" {
  source        = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"
  bucket_prefix = "moj-property-datalake-"

  custom_kms_key     = aws_kms_key.data_kms_key.arn
  versioning_enabled = true

  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }
  tags = local.tags
}

module "lakeformation_database" {
  source = "./modules/lakeformation_database"

  for_each = toset(local.application_data.datalake_databases)

  // Ternary based on env name
  database_name         = "${each.key}${local.environment == "production" ? "" : "_${local.environment}"}"
  location_bucket       = module.lakeformation_bucket.bucket.id
  location_prefix       = "${each.key}/${local.environment == "production" ? "" : "${local.environment}/"}"
  kms_key_id            = aws_kms_key.data_kms_key.arn
  hybrid_access_enabled = false
  validate_location     = false
}


resource "aws_lakeformation_permissions" "export_processor_planetfm_raw" {
  principal   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/planetfm-database-export-processor"
  permissions = ["ALL"]

  database {
    name = "planetfm-raw"
  }

  depends_on = [aws_lakeformation_data_lake_settings.lake_formation]
}

resource "aws_lakeformation_permissions" "export_processor_planetfm_raw_tables" {
  principal   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/planetfm-database-export-processor"
  permissions = ["ALL"]

  table {
    database_name = "planetfm-raw"
    wildcard      = true
  }

  depends_on = [aws_lakeformation_data_lake_settings.lake_formation]
}

resource "aws_lakeformation_lf_tag" "domain_tag" {
  key    = "domain"
  values = ["property"]

  depends_on = [aws_lakeformation_data_lake_settings.lake_formation]
}
