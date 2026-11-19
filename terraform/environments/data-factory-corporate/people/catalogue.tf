locals {
  glue_catalog_arn       = "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:catalog"
  sherlock_landing_prefix = "avature-sherlock"

  # Add independent buckets or prefixes here; an empty prefix registers the whole bucket.
  lakeformation_locations = {
    sherlock = {
      bucket_name = module.sherlock_landing_bucket_mp.bucket.bucket
      prefix      = ""
      kms_key_arn = module.sherlock_kms_key.key_arn
      role_name   = "sherlock_glue_database_${local.environment}-s3-access"
    }
  }
}

data "aws_iam_roles" "modernisation_platform_sandbox_role" {
  name_regex  = "AWSReservedSSO_modernisation-platform-sandbox_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

resource "aws_lakeformation_data_lake_settings" "your_lake_settings_name" {
  admins = concat(
    [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-plan",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-apply",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/MemberInfrastructureAccess",
      aws_iam_role.analytical_platform_data_share.arn,
    ],
    [
      for role_name in data.aws_iam_roles.modernisation_platform_sandbox_role.names :
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${role_name}"
    ]
  )
}

module "sherlock_glue_database" {
  source = "./modules/glue-database"

  database_name = "sherlock_glue_database_${local.environment}"

  storage = {
    bucket_name = module.sherlock_landing_bucket_mp.bucket.bucket
    prefix      = local.sherlock_landing_prefix
  }

}

module "lakeformation_locations" {
  for_each = local.lakeformation_locations
  source   = "./modules/lakeformation-location"

  bucket_name = each.value.bucket_name
  prefix      = each.value.prefix
  kms_key_arn = each.value.kms_key_arn
  role_name   = each.value.role_name
}