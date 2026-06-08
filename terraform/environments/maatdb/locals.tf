#### This file can be used to store locals specific to the member account ####

# Global Locals

locals {

  region = "eu-west-2"

  build_s3              = local.application_data.accounts[local.environment].build_s3
  build_ftp             = local.application_data.accounts[local.environment].build_ftp
  build_ses             = local.application_data.accounts[local.environment].build_ses
  build_ec2             = local.application_data.accounts[local.environment].build_ec2
  build_transfer        = local.application_data.accounts[local.environment].build_transfer
  build_hub_integration = local.application_data.accounts[local.environment].build_hub_integration

  ftp_layer_bucket          = local.application_data.accounts[local.environment].ftp_layer_bucket
  ftp_layer_folder_location = local.application_data.accounts[local.environment].ftp_layer_folder_location
  ftp_layer_source_zip      = local.application_data.accounts[local.environment].ftp_layer_source_zip

  python_runtime = local.application_data.accounts[local.environment].python_runtime

  ftp_sftp_port   = local.application_data.accounts[local.environment].ftp_sftp_port
  ftp_remote_path = local.application_data.accounts[local.environment].ftp_remote_path

  laa_general_kms_arn = data.aws_kms_key.general_shared.arn

  lambda_source_hashes = [
    for f in fileset("./lambda/cloudwatch_alarm_slack_integration", "**") :
    sha256(file("${path.module}/lambda/cloudwatch_alarm_slack_integration/${f}"))
  ]

  lambda_folder_name = ["lambda_delivery", "cloudwatch_sns_layer"]
}