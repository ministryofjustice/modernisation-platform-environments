resource "aws_glue_crawler" "data" {
  for_each = aws_glue_catalog_database.data

  name          = each.key
  database_name = each.key
  role          = module.glue_crawler_iam_role.name

  s3_target {
    path = "s3://${module.mojap_next_poc_data_s3_bucket.s3_bucket_id}/${each.key}"
  }
}
