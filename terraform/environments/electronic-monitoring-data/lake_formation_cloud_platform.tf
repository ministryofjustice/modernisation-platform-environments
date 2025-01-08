locals {
  env_          = "${local.environment_shorthand}_"
  cap_dw_tables = local.is-production ? ["contact_history", "equipment_details", "event_history", "incident", "order_details", "services", "suspension_of_visits", "violations", "visit_details"] : []
  am_tables     = local.is-production ? ["am_contact_history", "am_equipment_details", "am_incident", "am_order_details", "am_services", "am_visit_details"] : []
}

resource "aws_lakeformation_resource" "data_bucket" {
  arn = module.s3-create-a-derived-table-bucket.bucket.arn
}

module "share_current_version" {
  count  = local.is-test ? 1 : 0
  source = "./modules/lakeformation"
  table_filters = {
    "account" = "__current=true"
  }
  role_arn                = module.cmt_front_end_assumable_role.iam_role_arn
  database_name           = "staged_fms_${local.env_}dbt"
  data_engineer_role_arn  = try(one(data.aws_iam_roles.data_engineering_roles.arns))
  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
}

# module "cap_dw_excluding_specials" {
#   for_each = toset(local.cap_dw_tables)
#   source   = "./modules/lakeformation"
#   table_filters = {
#     (each.key) = "specials_flag=0"
#   }
#   role_arn                = module.cmt_front_end_assumable_role.iam_role_arn
#   database_name           = "historic_api_mart_tables_historic_dev_dbt"
#   data_engineer_role_arn  = try(one(data.aws_iam_roles.data_engineering_roles.arns))
#   data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
# }

# module "cap_dw_including_specials" {
#   for_each = toset(local.cap_dw_tables)
#   source   = "./modules/lakeformation"
#   table_filters = {
#     (each.key) = ""
#   }
#   role_arn                = module.specials_cmt_front_end_assumable_role.iam_role_arn
#   database_name           = "historic_api_mart_tables_historic_dev_dbt"
#   data_engineer_role_arn  = try(one(data.aws_iam_roles.data_engineering_roles.arns))
#   data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
# }

# module "am_for_non_specials_role" {
#   for_each = toset(local.am_tables)
#   source   = "./modules/lakeformation"
#   table_filters = {
#     (each.key) = ""
#   }
#   role_arn                = module.cmt_front_end_assumable_role.iam_role_arn
#   database_name           = "historic_api_mart_tables_historic_dev_dbt"
#   data_engineer_role_arn  = try(one(data.aws_iam_roles.data_engineering_roles.arns))
#   data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
# }

# module "am_for_specials_role" {
#   for_each = toset(local.am_tables)
#   source   = "./modules/lakeformation"
#   table_filters = {
#     (each.key) = ""
#   }
#   role_arn                = module.specials_cmt_front_end_assumable_role.iam_role_arn
#   database_name           = "historic_api_mart_tables_historic_dev_dbt"
#   data_engineer_role_arn  = try(one(data.aws_iam_roles.data_engineering_roles.arns))
#   data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
# }
