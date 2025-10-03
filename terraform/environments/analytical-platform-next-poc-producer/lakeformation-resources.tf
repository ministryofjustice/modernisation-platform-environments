resource "aws_lakeformation_resource" "mojap_next_poc_data_s3" {
  arn                     = module.mojap_next_poc_data_s3_bucket.s3_bucket_arn
  use_service_linked_role = true
}
