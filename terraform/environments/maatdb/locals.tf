#### This file can be used to store locals specific to the member account ####


locals {

  region = "eu-west-2"

  build_s3  = local.application_data.accounts[local.environment].build_s3
  build_ftp = local.application_data.accounts[local.environment].build_ftp

  bucket_names = [
    "ftp-${local.application_name}-${local.environment}-outbouond",
    "ftp-${local.application_name}-${local.environment}-inbound",
  ]

}