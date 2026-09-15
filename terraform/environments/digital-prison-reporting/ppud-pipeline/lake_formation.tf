# Combine the SSO role(s) with the cross-account role used by 
# create a derived table (cadet)
locals {
  lf_principals_not_admin = local.is-test ? toset([]) : toset(concat(
    [data.aws_iam_role.dataapi_cross_role[0].arn],
    tolist(try(data.aws_iam_roles.data_engineering_roles.arns, toset([])))
  ))
}

# Give the key roles role 'All' permissions on all DBs in 
# application_variables.json
resource "aws_lakeformation_permissions" "share_dbs_all_permissions" {
  # one instance per (database × principal)
  for_each = local.is-development ? {
    for combo in flatten([
      for share_index, share in local.analytical_platform_share : [
        for resource_share in share.resource_shares : [
          for principal in toset(concat(
            [data.aws_iam_role.analytical_platform_share_role[share_index].arn],
            tolist(local.lf_principals_not_admin)
            )) : {
            key            = "db-${resource_share.glue_database}-${substr(md5(principal), 0, 10)}"
            resource_share = resource_share
            principal      = principal
          }
        ]
      ]
    ]) : combo.key => combo
  } : {}

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
  for_each = local.is-development ? {
    for combo in flatten([
      for share_index, share in local.analytical_platform_share : [
        for resource_share in share.resource_shares : [
          for principal in toset(concat(
            [data.aws_iam_role.analytical_platform_share_role[share_index].arn],
            tolist(local.lf_principals_not_admin)
            )) : {
            key           = "tbl-${resource_share.glue_database}-${substr(md5(principal), 0, 10)}"
            database_name = resource_share.glue_database
            principal     = principal
          }
        ]
      ]
    ]) : combo.key => combo
  } : {}

  principal                     = each.value.principal
  permissions                   = ["ALL"]
  permissions_with_grant_option = ["ALL"]

  table {
    database_name = each.value.database_name
    wildcard      = true
  }
}
