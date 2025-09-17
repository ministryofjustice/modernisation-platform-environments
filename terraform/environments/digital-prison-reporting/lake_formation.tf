resource "aws_lakeformation_data_lake_settings" "lake_formation" {
  admins = flatten([
    [for share in local.analytical_platform_share : aws_iam_role.analytical_platform_share_role[share.target_account_name].arn],
    data.aws_iam_session_context.current.issuer_arn,
    ]
  )

  # Ensure permissions are null to avoid LF being
  create_database_default_permissions {
    # These settings should replicate current behaviour: LakeFormation is Ignored
    permissions = []
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }

  create_table_default_permissions {
    # These settings should replicate current behaviour: LakeFormation is Ignored
    permissions = []
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }

  parameters = {
    "CROSS_ACCOUNT_VERSION" = "4"
  }
}

# Give the cadet cross-account role LF data access
resource "aws_iam_role_policy_attachment" "dataapi_cross_role_lake_formation_data_access" {
  role       = aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.lake_formation_data_access.arn
}

# Give the cadet cross-account role data location access
# structured and working are required
resource "aws_lakeformation_permissions" "data_location_access_structured_historical" {
  principal   = aws_iam_role.dataapi_cross_role.arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = "arn:aws:s3:::${local.project}-structured-historical-${local.environment}"
  }
}

resource "aws_lakeformation_permissions" "data_location_access_working" {
  principal   = aws_iam_role.dataapi_cross_role.arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = "arn:aws:s3:::${local.project}-working-${local.environment}"
  }
}


locals {
  super_dbs = [
    "curated_prisons_history_dev_dbt",
    "staged_prisons_history_dev_dbt"
  ]
}

resource "aws_lakeformation_permissions" "super_permissions" {
  for_each = toset(local.super_dbs)

  principal                     = "arn:aws:iam::771283872747:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_modernisation-platform-data-eng_a2da3e45320e1580"
  permissions                   = ["ALL"]
  permissions_with_grant_option = ["ALL"]

  database {
    name = each.value
  }
}
