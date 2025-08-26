resource "aws_glue_catalog_database" "moj" {
  name         = "moj"
  description  = "MoJ data"
  location_uri = "s3://${module.mojap_next_poc_data_s3_bucket.s3_bucket_id}/${local.data_folder_prefix}"
}
