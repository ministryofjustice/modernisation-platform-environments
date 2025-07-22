resource "aws_glue_catalog_database" "gds_data" {
  name         = "gds-data"
  description  = "GDS data"
  location_uri = "s3://${module.s3_bucket.s3_bucket_id}/${local.gds_data_folder_prefix}"
}
