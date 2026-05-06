locals {
  bucket_configuration                  = local.application_data.accounts[local.environment].bucket_configuration
  iam_configuration                     = local.application_data.accounts[local.environment].iam_configuration
  malware_scanning_processing_bucket_name = module.s3_bucket[local.iam_configuration.malware_scanning_processing_bucket_key].s3_bucket_id
}