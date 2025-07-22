resource "aws_glue_crawler" "moj_headcount_and_payroll_data" {
  name          = "moj-headcount-and-payroll-data"
  database_name = aws_glue_catalog_database.moj_headcount_and_payroll_data.name
  role          = module.glue_crawler_iam_role.iam_role_name

  s3_target {
    path = "s3://${module.s3_bucket.s3_bucket_id}/${local.headcount_and_payroll_data_folder_prefix}"
  }
}
