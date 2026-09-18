# Combine the SSO role(s) with the cross-account role used by 
# create a derived table (cadet)
locals {
  lf_principals_not_admin = local.is-test ? toset([]) : toset(concat(
    [data.aws_iam_role.dataapi_cross_role[0].arn],
    tolist(try(data.aws_iam_roles.data_engineering_roles[0].arns, toset([])))
  ))
}

# Give the key roles role 'All' permissions on all DBs in 
# application_variables.json
resource "aws_lakeformation_permissions" "share_dbs_all_permissions" {
  # one instance per (database × principal)
  for_each = (local.is-development || local.is-preproduction) ? {
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
  for_each = (local.is-development || local.is-preproduction) ? {
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

# Give the ap share policy role Glue permissions on the share resources
data "aws_iam_policy_document" "analytical_platform_share_policy_ppud" {
  for_each = (local.is-development || local.is-preproduction) ? local.analytical_platform_share : {}

  statement {
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetPartition",
      "glue:GetTags",
      "glue:DeleteDatabase",
      "glue:TagResource",
      "glue:UpdateDatabase"
    ]
    resources = flatten([
      for resource in each.value.resource_shares : [
        "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:database/${resource.glue_database}",
        formatlist("arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/${resource.glue_database}/%s", resource.glue_tables),
        "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:userDefinedFunction/${resource.glue_database}/*",
        "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:catalog"
      ]
    ])
  }
}

resource "aws_iam_role_policy" "analytical_platform_share_policy_attachment_ppud" {
  for_each = (local.is-development || local.is-preproduction) ? local.analytical_platform_share : {}

  name   = "${each.value.target_account_name}-share-policy-ppud"
  role   = data.aws_iam_role.analytical_platform_share_role[each.key].name
  policy = data.aws_iam_policy_document.analytical_platform_share_policy_ppud[each.key].json
}
