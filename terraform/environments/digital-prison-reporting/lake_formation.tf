# Combine the SSO role(s) with the cross-account role used by 
# create a derived table (cadet)
locals {
  lf_principals_not_admin = toset(concat(
    [aws_iam_role.dataapi_cross_role.arn],
    tolist(try(data.aws_iam_roles.data_engineering_roles.arns, toset([])))
  ))
}

resource "aws_lakeformation_data_lake_settings" "lake_formation" {
  admins = flatten([
    [for share in
      local.analytical_platform_share : aws_iam_role.analytical_platform_share_role[share.target_account_name].arn
    ],
    data.aws_iam_session_context.current.issuer_arn
  ])


  # Ensure permissions are null to avoid LF being
  create_database_default_permissions {
    # These settings should replicate current behaviour: LakeFormation is Ignored
    permissions = ["ALL"]
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }

  create_table_default_permissions {
    # These settings should replicate current behaviour: LakeFormation is Ignored
    permissions = ["ALL"]
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }

  parameters = {
    "CROSS_ACCOUNT_VERSION" = "4"
  }
}

# Give the key roles role 'All' permissions on all DBs in 
# application_variables.json
resource "aws_lakeformation_permissions" "share_dbs_all_permissions" {
  # one instance per (database × principal)
  for_each = {
    for combo in flatten([
      for share_index, share in local.analytical_platform_share : [
        for resource_share in share.resource_shares : [
          for principal in toset(concat(
            [aws_iam_role.analytical_platform_share_role[share_index].arn],
            tolist(local.lf_principals_not_admin)
            )) : {
            key            = "db-${resource_share.glue_database}-${substr(md5(principal), 0, 10)}"
            resource_share = resource_share
            principal      = principal
          }
        ]
      ]
    ]) : combo.key => combo
  }

  principal                     = each.value.principal
  permissions                   = ["ALL"]
  permissions_with_grant_option = ["ALL"]

  database {
    name = each.value.resource_share.glue_database
  }
}

# Grant 'ALL' on *all tables* within each shared database
resource "aws_lakeformation_permissions" "table_all_permissions" {
  # reuse the same keying pattern
  for_each = {
    for combo in flatten([
      for share_index, share in local.analytical_platform_share : [
        for resource_share in share.resource_shares : [
          for principal in toset(concat(
            [aws_iam_role.analytical_platform_share_role[share_index].arn],
            tolist(local.lf_principals_not_admin)
            )) : {
            key           = "tbl-${resource_share.glue_database}-${substr(md5(principal), 0, 10)}"
            database_name = resource_share.glue_database
            principal     = principal
          }
        ]
      ]
    ]) : combo.key => combo
  }

  principal                     = each.value.principal
  permissions                   = ["ALL"]
  permissions_with_grant_option = ["ALL"]

  table {
    database_name = each.value.database_name
    wildcard      = true
  }
}

# Grant DATA_LOCATION_ACCESS to analytical platform share roles on their configured S3 buckets
resource "aws_lakeformation_permissions" "share_role_data_location_permissions" {
  for_each = {
    for pair in flatten([
      for share_index, share in local.analytical_platform_share : [
        for location_index, data_location in share.data_locations : {
          key           = "${share_index}-${location_index}"
          data_location = data_location
          share_index   = share_index
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

# Grant QuickSight user permissions using LF tags
resource "aws_lakeformation_permissions" "quicksight_user_lf_tag_permissions" {
  principal   = "arn:aws:iam::684969100054:role/fake-cadet-runner-not-working"
  permissions = ["DESCRIBE", "SELECT"]

  lf_tag_policy {
    resource_type = "TABLE"
    expression {
      key    = "sensitive"
      values = ["false"]
    }
    expression {
      key    = "domain"
      values = ["prisons"]
    }
    expression {
      key    = "service"
      values = ["incident_reporting"]
    }
  }
}