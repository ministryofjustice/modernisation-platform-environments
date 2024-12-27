locals {
  env_ = "${local.environment_shorthand}_"
}

module "share_current_version" {
  source = "./modules/lakeformation"
  table_filters = {
    "account" = "__current=true"
  }
  role_arn               = module.cmt_front_end_assumable_role.iam_role_arn
  database_name          = "staged_fms_${local.env_}dbt"
  data_engineer_role_arn = try(one(data.aws_iam_roles.data_engineering_roles.arns))
  data_bucket            = module.s3-create-a-derived-table-bucket.bucket
}
