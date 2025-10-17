resource "aws_glue_catalog_database" "main" {
  for_each = local.databases

  name         = each.key
  location_uri = "s3://${module.mojap_next_poc_data_s3_bucket.s3_bucket_id}/${each.key}"
}
