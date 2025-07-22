resource "aws_glue_crawler" "gds_data" {
  name          = "gds-data"
  database_name = aws_glue_catalog_database.gds_data.name
  role          = module.glue_crawler_iam_role.iam_role_name

  s3_target {
    path = "s3://${module.s3_bucket.s3_bucket_id}/${local.gds_data_folder_prefix}"
  }
}
