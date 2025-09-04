resource "aws_glue_crawler" "main" {
  for_each = local.databases

  name          = each.key
  database_name = each.key
  role          = module.glue_crawler_iam_role.name

  dynamic "s3_target" {
    for_each = each.value.tables
    content {
      path = "s3://${module.mojap_next_poc_data_s3_bucket.s3_bucket_id}/${each.key}/${s3_target.value}/"
    }
  }
}
