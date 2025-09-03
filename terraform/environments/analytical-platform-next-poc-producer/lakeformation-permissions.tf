# This permission doesn't seem to be required, so removing it
# resource "aws_lakeformation_permissions" "share_data_location" {
#   principal                     = local.hub_account_id
#   permissions                   = ["DATA_LOCATION_ACCESS"]
#   permissions_with_grant_option = ["DATA_LOCATION_ACCESS"]

#   data_location {
#     arn = module.mojap_next_poc_data_s3_bucket.s3_bucket_arn
#   }
# }

resource "aws_lakeformation_permissions" "share_database_hub" {
  principal                     = local.hub_account_id
  permissions                   = ["DESCRIBE"]
  permissions_with_grant_option = ["DESCRIBE"]

  database {
    name = aws_glue_catalog_database.moj.name
  }
}

resource "aws_lakeformation_permissions" "share_tables_hub" {
  principal                     = local.hub_account_id
  permissions                   = ["SELECT", "DESCRIBE"]
  permissions_with_grant_option = ["SELECT", "DESCRIBE"]

  table {
    database_name = aws_glue_catalog_database.moj.name
    wildcard      = true
  }
}

## IN ACCOUNT TESTING TAGS
resource "aws_lakeformation_permissions" "crawler_access_moj" {
  principal   = module.glue_crawler_iam_role.arn
  permissions = ["ALL"]

  lf_tag_policy {
    resource_type = "DATABASE"
    expression {
      key    = "business-unit"
      values = ["Central Digital"]
    }
  }
}

resource "aws_lakeformation_permissions" "user_access_moj" {
  principal   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.sso_platform_engineer_admin.names)}"
  permissions = ["ALL"]

  lf_tag_policy {
    resource_type = "DATABASE"
    expression {
      key    = "business-unit"
      values = ["Central Digital"]
    }
  }
}

resource "aws_lakeformation_permissions" "user_access_moj_table" {
  principal   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.sso_platform_engineer_admin.names)}"
  permissions = ["SELECT", "DESCRIBE"]

  lf_tag_policy {
    resource_type = "TABLE"
    expression {
      key    = "business-unit"
      values = ["Central Digital"]
    }
  }
}
