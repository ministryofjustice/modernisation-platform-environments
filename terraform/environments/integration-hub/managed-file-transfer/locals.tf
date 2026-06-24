locals {
  bucket_configuration = local.application_data.accounts[local.environment].bucket_configuration
  custom_idp_configuration = merge(
    {
      log_level           = "INFO"
      secret_prefix       = "transfer/"
      user_name_delimiter = "@@"
      ingress_cidr_blocks = ["0.0.0.0/0"]
    },
    try(local.application_data.accounts[local.environment].custom_idp_configuration, {})
  )
  iam_configuration = local.application_data.accounts[local.environment].iam_configuration
  vpc_configuration = local.application_data.accounts[local.environment].vpc_configuration
}
