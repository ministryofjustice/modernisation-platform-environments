resource "aws_glue_crawler" "data" {
  name          = "data"
  database_name = aws_glue_catalog_database.moj.name
  role          = module.glue_crawler_iam_role.name

  s3_target {
    path = "s3://${module.mojap_next_poc_data_s3_bucket.s3_bucket_id}/${local.data_folder_prefix}"
  }
}
