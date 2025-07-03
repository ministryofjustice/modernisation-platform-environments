#### This file can be used to store locals specific to the member account ####

# Global Locals

locals {

  region = "eu-west-2"

  build_s3       = local.application_data.accounts[local.environment].build_s3
  build_ftp      = local.application_data.accounts[local.environment].build_ftp
  build_ses      = local.application_data.accounts[local.environment].build_ses
  build_ec2      = local.application_data.accounts[local.environment].build_ec2
  build_transfer = local.application_data.accounts[local.environment].build_transfer
  
  ftp_layer_bucket = local.application_data.accounts[local.environment].ftp_layer_bucket
  ftp_layer_folder_location = local.application_data.accounts[local.environment].ftp_layer_folder_location

  laa_general_kms_arn = data.aws_kms_key.general_shared.arn

}