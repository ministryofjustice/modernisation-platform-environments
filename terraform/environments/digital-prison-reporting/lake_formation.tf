resource "aws_lakeformation_data_lake_settings" "lake_formation" {
  admins = [
    data.aws_iam_session_context.current.issuer_arn,
  ]

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

resource "aws_lakeformation_permissions" "share_role_all_permissions" {
  for_each    = toset([for share in local.analytical_platform_share : share.target_account_name])
  principal   = aws_iam_role.analytical_platform_share_role[each.key].arn
  permissions = ["ALL"]

  database {
    name = local.lake_formation_database_name
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



