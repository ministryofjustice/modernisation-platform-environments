locals {
  mft_upload_bucket_parameter_prefix = "/${local.resource_application_name}/managed-file-transfer/${local.environment}/upload-bucket"
  enable_alerting                    = contains(["development", "production"], local.environment)
}
