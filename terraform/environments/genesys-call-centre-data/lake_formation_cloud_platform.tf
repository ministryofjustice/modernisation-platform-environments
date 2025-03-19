locals {
  env_ = "${local.environment_shorthand}_"
  cap_dw_tables = local.is-production || local.is-test ? [
    "activity_codes",
    "agent_schedules_items"
  ] : []
  am_tables = local.is-production ? [
    "activity_codes",
    "agent_schedules_items"
  ] : []
}

resource "aws_lakeformation_resource" "data_bucket" {
  arn = module.s3_bucket_landing_archive_ingestion_curated["call-centre-ingestion-"].bucket.arn
}

# module "share_current_version" {
#   count  = local.is-test ? 1 : 0
#   source = "./modules/lakeformation_w_data_filter"
#   table_filters = {
#     "account" = "__current=true"
#   }
#   role_arn                = module.cmt_front_end_assumable_role.iam_role_arn
#   database_name           = "staged_genesys_laa_${local.env_}dbt"
#   data_engineer_role_arn  = try(one(data.aws_iam_roles.data_engineering_roles.arns))
#   data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
# }

# module "cap_dw_excluding_specials" {
#   for_each = toset(local.cap_dw_tables)
#   source   = "./modules/lakeformation_w_data_filter"
#   table_filters = {
#     (each.key) = "specials_flag=0"
#   }
#   role_arn                = module.cmt_front_end_assumable_role.iam_role_arn
#   database_name           = "genesys_laa"
#   data_engineer_role_arn  = try(one(data.aws_iam_roles.data_engineering_roles.arns))
#   data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
# }

# module "cap_dw_including_specials" {
#   for_each = toset(local.cap_dw_tables)
#   source   = "./modules/lakeformation_w_data_filter"
#   table_filters = {
#     (each.key) = ""
#   }
#   role_arn                = module.specials_cmt_front_end_assumable_role.iam_role_arn
#   database_name           = "genesys_laa"
#   data_engineer_role_arn  = try(one(data.aws_iam_roles.data_engineering_roles.arns))
#   data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
# }
