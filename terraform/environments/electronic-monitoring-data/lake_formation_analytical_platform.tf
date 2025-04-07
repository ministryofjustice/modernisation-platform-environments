locals {
  ap_shares = {
    database_name = "mart${local.dbt_suffix}"
    tables        = { "visits" : "is_general=true" }
    github_user_names = [
      "matt-heery",
    ]
  }
  ap_shares_combined = flatten([
    for table_name, filter in local.ap_shares.tables : [
      for user_name in local.ap_shares.github_user_names : {
        table_name = table_name
        filter     = filter
        user_name  = user_name
      }
    ]
  ])
  ap_shares_filtered = local.is-development ? [] : local.ap_shares_combined
}


module "share_marts" {
  for_each                     = { for idx, share in local.ap_shares_filtered : idx => share }
  source                       = "./modules/cross_account_lf_data_filter"
  destination_account_id       = local.environment_management.account_ids["analytical-platform-data-production"]
  destination_account_role_arn = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/alpha_user_${each.value.user_name}"
  table_name                   = each.value.table_name
  table_filter                 = each.value.filter
  data_bucket_lf_arn           = aws_lakeformation_resource.data_bucket.arn
  database_name                = local.ap_shares.database_name
}
