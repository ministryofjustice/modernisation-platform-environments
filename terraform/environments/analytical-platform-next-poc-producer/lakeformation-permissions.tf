## IN ACCOUNT
resource "aws_lakeformation_permissions" "crawler_access" {
  for_each = aws_glue_catalog_database.main

  principal   = module.glue_crawler_iam_role.arn
  permissions = ["ALL"]

  database {
    name = each.value.name
  }
}

resource "aws_lakeformation_permissions" "sso_platform_engineer_admin_access_db" {
  for_each = aws_glue_catalog_database.main

  principal   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.sso_platform_engineer_admin.names)}"
  permissions = ["ALL"]

  database {
    name = each.value.name
  }
}

resource "aws_lakeformation_permissions" "sso_platform_engineer_admin_access_tables" {
  for_each = aws_glue_catalog_database.main

  principal   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.sso_platform_engineer_admin.names)}"
  permissions = ["SELECT", "DESCRIBE"]

  table {
    database_name = each.value.name
    wildcard      = true
  }
}

## HUB ACCESS
# Unsure if this is required still
# resource "aws_lakeformation_permissions" "share_data_location" {
#   principal                     = local.hub_account_id
#   permissions                   = ["DATA_LOCATION_ACCESS"]
#   permissions_with_grant_option = ["DATA_LOCATION_ACCESS"]

#   data_location {
#     arn = module.mojap_next_poc_data_s3_bucket.s3_bucket_arn
#   }
# }

## WILDCARD
resource "aws_lakeformation_permissions" "share_wildcard_db_database_hub" {
  principal                     = local.hub_account_id
  permissions                   = ["DESCRIBE"]
  permissions_with_grant_option = ["DESCRIBE"]

  database {
    name = aws_glue_catalog_database.main["wildcard_db"].name
  }
}

resource "aws_lakeformation_permissions" "share_wildcard_db_tables_hub" {
  principal                     = local.hub_account_id
  permissions                   = ["SELECT", "DESCRIBE"]
  permissions_with_grant_option = ["SELECT", "DESCRIBE"]

  table {
    database_name = aws_glue_catalog_database.main["wildcard_db"].name
    wildcard      = true
  }
}

## INDIVIDUAL
resource "aws_lakeformation_permissions" "share_individual_db_database_hub" {
  principal                     = local.hub_account_id
  permissions                   = ["DESCRIBE"]
  permissions_with_grant_option = ["DESCRIBE"]

  database {
    name = aws_glue_catalog_database.main["individual_db"].name
  }
}

resource "aws_lakeformation_permissions" "share_individual_db_tables_hub" {
  principal                     = local.hub_account_id
  permissions                   = ["SELECT", "DESCRIBE"]
  permissions_with_grant_option = ["SELECT", "DESCRIBE"]

  table {
    database_name = aws_glue_catalog_database.main["individual_db"].name
    name          = "shared_tbl"
  }
}
