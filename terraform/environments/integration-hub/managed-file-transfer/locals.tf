locals {
  bucket_configuration = local.application_data.accounts[local.environment].bucket_configuration
  iam_configuration    = local.application_data.accounts[local.environment].iam_configuration
}