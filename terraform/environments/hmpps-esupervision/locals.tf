locals {
  rekog_s3_bucket_name = "${terraform.workspace}-rekognition-uploads"

  developer_role_suffix = local.application_data.accounts[local.environment].developer_role_suffix
}