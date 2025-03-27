# locals {
#   env_ = "${local.environment_shorthand}_"
#   laa_dw_tables = local.is-production || local.is-test || local.is-development ? [
#     "activity_codes", 
#     "agent_schedules_items", 
#     "agent_schedules", 
#     "agents", 
#     "business_units",
#     "conversation_job", 
#     "conversations", 
#     "division", 
#     "flow_aggregates", 
#     "flow_outcomes",
#     "flows", 
#     "groups", 
#     "historical_adherence", 
#     "ivr_milestones", 
#     "locations",
#     "management_units", 
#     "ob_wrapup", 
#     "participant_attributes", 
#     "planning_groups",
#      "presence_definition",
#     "queue_membership_audit_job", 
#     "realtime", 
#     "routing_languages", 
#     "routing_queuemembers", 
#     "routing_queues",
#     "routing_skills", 
#     "service_goals", 
#     "sta_topics", 
#     "system_presence", 
#     "time_off_limits",
#     "time_off_plans", 
#     "time_off_requests", 
#     "user_details_job", 
#     "user_status", 
#     "users",
#     "wfm_intraday", 
#     "wfm_schedules_job", 
#     "work_plan_rotation", 
#     "work_plans", 
#     "work_teams"
#   ] : []
# }

# resource "aws_lakeformation_resource" "data_bucket" {
#   arn = module.s3_bucket_landing_archive_ingestion_curated["call-centre-ingestion-"].bucket.arn
# }

# # module "share_current_version" {
# #   count  = local.is-test ? 1 : 0
# #   source = "./modules/lakeformation_w_data_filter"
# #   table_filters = {
# #     "account" = "__current=true"
# #   }
# #   role_arn                = module.laa_front_end_assumable_role.iam_role_arn
# #   database_name           = "call_centre_laa_${local.env_}dbt"
# #   data_engineer_role_arn  = try(one(data.aws_iam_roles.data_engineering_roles.arns))
# #   data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
# # }

# # module "cap_dw_excluding_specials" {
# #   for_each = toset(local.laa_dw_tables)
# #   source   = "./modules/lakeformation_w_data_filter"
# #   table_filters = {
# #     (each.key) = "specials_flag=0"
# #   }
# #   role_arn                = module.cmt_front_end_assumable_role.iam_role_arn
# #   database_name           = "historic_api_mart"
# #   data_engineer_role_arn  = try(one(data.aws_iam_roles.data_engineering_roles.arns))
# #   data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
# # }

# # module "cap_dw_including_specials" {
# #   for_each = toset(local.laa_dw_tables)
# #   source   = "./modules/lakeformation_w_data_filter"
# #   table_filters = {
# #     (each.key) = ""
# #   }
# #   role_arn                = module.specials_cmt_front_end_assumable_role.iam_role_arn
# #   database_name           = "historic_api_mart"
# #   data_engineer_role_arn  = try(one(data.aws_iam_roles.data_engineering_roles.arns))
# #   data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
# # }

# # module "am_for_non_specials_role" {
# #   for_each = toset(local.am_tables)
# #   source   = "./modules/lakeformation_w_data_filter"
# #   table_filters = {
# #     (each.key) = ""
# #   }
# #   role_arn                = module.cmt_front_end_assumable_role.iam_role_arn
# #   database_name           = "historic_api_mart_tables_historic_dev_dbt"
# #   data_engineer_role_arn  = try(one(data.aws_iam_roles.data_engineering_roles.arns))
# #   data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
# # }

# # module "am_for_specials_role" {
# #   for_each = toset(local.am_tables)
# #   source   = "./modules/lakeformation_w_data_filter"
# #   table_filters = {
# #     (each.key) = ""
# #   }
# #   role_arn                = module.specials_cmt_front_end_assumable_role.iam_role_arn
# #   database_name           = "historic_api_mart_tables_historic_dev_dbt"
# #   data_engineer_role_arn  = try(one(data.aws_iam_roles.data_engineering_roles.arns))
# #   data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
# # }
