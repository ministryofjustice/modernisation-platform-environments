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
  for_each = {
    for pair in flatten([
      for share_index, share in local.analytical_platform_share : [
        for rs_index, resource_share in share.resource_shares : {
          key = "${share_index}-${rs_index}"
          resource_share = resource_share
          share_index = share_index
        }
      ]
    ]) : pair.key => pair
  }
  
  principal   = aws_iam_role.analytical_platform_share_role[each.value.share_index].arn
  permissions = ["ALL"]
  permissions_with_grant_option = ["ALL"]

  database {
    name = each.value.resource_share.glue_database
  }
}

# Grant DATA_LOCATION_ACCESS to analytical platform share roles on their configured S3 buckets
resource "aws_lakeformation_permissions" "share_role_data_location_permissions" {
  for_each = {
    for pair in flatten([
      for share_index, share in local.analytical_platform_share : [
        for location_index, data_location in share.data_locations : {
          key = "${share_index}-${location_index}"
          data_location = data_location
          share_index = share_index
        }
      ]
    ]) : pair.key => pair
  }
  
  principal   = aws_iam_role.analytical_platform_share_role[each.value.share_index].arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = "arn:aws:s3:::${each.value.data_location}"
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



