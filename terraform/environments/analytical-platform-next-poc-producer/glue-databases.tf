resource "aws_glue_catalog_database" "moj_headcount_and_payroll_data" {
  name         = "moj-headcount-and-payroll-data"
  description  = "MoJ headcount and payroll data"
  location_uri = "s3://${module.s3_bucket.s3_bucket_id}/${local.headcount_and_payroll_data_folder_prefix}"
}
