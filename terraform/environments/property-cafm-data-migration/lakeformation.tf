# ------------------------------------------------------------------------
# Lake Formation - admin permissions
# https://user-guide.modernisation-platform.service.justice.gov.uk/runbooks/adding-admin-data-lake-formation-permissions.html
# SSO role (sandbox/data-eng) is NOT an LF admin to avoid conflicts with
# explicit grants managed via data-engineering-datalake-access YAML.
# See: digital-prison-reporting lake_formation.tf for reference pattern.
# ------------------------------------------------------------------------

resource "aws_lakeformation_data_lake_settings" "lake_formation" {
  admins = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/MemberInfrastructureAccess",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/lakeformation-share-role",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-plan",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-apply",
  ]

  parameters = {
    "CROSS_ACCOUNT_VERSION" = "4"
  }
}

# Grant the staging export Lambda role Lake Formation permissions on the property database
# SSO admin grants (sandbox/data-eng) are managed via data-engineering-datalake-access YAML
resource "aws_lakeformation_permissions" "staging-export-database" {
  principal   = module.lambda-staging-export.role_arn
  permissions = ["DESCRIBE"]

  database {
    name = "property"
  }
}

resource "aws_lakeformation_permissions" "staging-export-tables" {
  principal   = module.lambda-staging-export.role_arn
  permissions = ["SELECT", "DESCRIBE"]

  table {
    database_name = "property"
    wildcard      = true
  }
}

# The property views chain through planetfm staging tables - grant LF access to that database too
resource "aws_lakeformation_permissions" "staging-export-planetfm-database" {
  principal   = module.lambda-staging-export.role_arn
  permissions = ["DESCRIBE"]

  database {
    name = "planetfm"
  }
}

resource "aws_lakeformation_permissions" "staging-export-planetfm-tables" {
  principal   = module.lambda-staging-export.role_arn
  permissions = ["SELECT", "DESCRIBE"]

  table {
    database_name = "planetfm"
    wildcard      = true
  }
}

resource "aws_lakeformation_permissions" "staging-export-concept-database" {
  principal   = module.lambda-staging-export.role_arn
  permissions = ["DESCRIBE"]

  database {
    name = "concept"
  }
}

resource "aws_lakeformation_permissions" "staging-export-concept-tables" {
  principal   = module.lambda-staging-export.role_arn
  permissions = ["SELECT", "DESCRIBE"]

  table {
    database_name = "concept"
    wildcard      = true
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
