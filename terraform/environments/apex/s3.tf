module "s3_bucket_lambda" {
  source = "./modules/s3"

  bucket_name = "laa-${local.application_name}-${local.environment}-mp" # Added suffix -mp to the name as it must be unique from the existing bucket in LZ
  # bucket_prefix not used in case bucket name get referenced as part of EC2 AMIs

  tags = merge(
    local.tags,
    { Name = "laa-${local.application_name}-${local.environment}-mp" }
  )

}