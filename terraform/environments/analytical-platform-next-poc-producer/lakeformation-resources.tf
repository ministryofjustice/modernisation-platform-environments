resource "aws_lakeformation_resource" "mojap_next_poc_data_s3" {
  arn                     = module.mojap_next_poc_data_s3_bucket.s3_bucket_arn
  use_service_linked_role = true
}

resource "aws_lakeformation_resource_lf_tags" "glue_moj_central_digital" {
  database {
    name = aws_glue_catalog_database.moj.name
  }

  lf_tag {
    key   = "business-unit"
    value = "Central Digital"
  }
}
