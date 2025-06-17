#### This file can be used to store locals specific to the member account ####


locals {

  region = "eu-west-2"

  build_s3  = local.application_data.accounts[local.environment].build_s3
  build_ftp = local.application_data.accounts[local.environment].build_ftp
  build_ses = local.application_data.accounts[local.environment].build_ses

# SES Specific Locals

  hosted_zone = local.application_data.accounts[local.environment].hosted_zone

  ses_domain = local.application_data.accounts[local.environment].hosted_zone
   
}