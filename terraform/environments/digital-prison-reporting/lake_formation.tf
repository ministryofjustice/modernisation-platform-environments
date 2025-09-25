# Combine the SSO role(s) with the cross-account role
locals {
  lf_principals_not_admin = toset(concat(
    [aws_iam_role.dataapi_cross_role.arn],
    tolist(try(data.aws_iam_roles.data_engineering_roles.arns, toset([])))
  ))
}

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

# Give LF DATA_LOCATION_ACCESS on structured-historical to all (non LF admin) principals
# Note: LF admin can't have ASSOCIATE permissions on LF tags
resource "aws_lakeformation_permissions" "data_location_access_structured_historical" {
  for_each    = local.lf_principals_not_admin
  principal   = each.value
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = "arn:aws:s3:::${local.project}-structured-historical-${local.environment}"
  }
}

# Give LF DATA_LOCATION_ACCESS on working to all (non LF admin) principals
# Note: LF admin can't have ASSOCIATE permissions on LF tags
resource "aws_lakeformation_permissions" "data_location_access_working" {
  for_each    = local.lf_principals_not_admin
  principal   = each.value
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = "arn:aws:s3:::${local.project}-working-${local.environment}"
  }
}

