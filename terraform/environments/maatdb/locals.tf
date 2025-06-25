#### This file can be used to store locals specific to the member account ####

# Global Locals

locals {

  region = "eu-west-2"

  build_s3     = local.application_data.accounts[local.environment].build_s3
  build_ftp    = local.application_data.accounts[local.environment].build_ftp
  build_ses    = local.application_data.accounts[local.environment].build_ses
  build_ec2    = local.application_data.accounts[local.environment].build_ec2

}