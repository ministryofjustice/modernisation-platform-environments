module "integration_hub_file_transfer_api" {
  source = "./modules/integration-hub-file-transfer-api"

  environment = local.environment
  tags        = local.tags

  upload_bucket = {
    arn         = data.aws_ssm_parameter.mft_upload_bucket_arn.value
    kms_key_arn = data.aws_ssm_parameter.mft_upload_bucket_kms_key_arn.value
    name        = data.aws_ssm_parameter.mft_upload_bucket_name.value
  }

  alarm_topic_arns = {
    high_priority = local.enable_alerting ? data.aws_sns_topic.mft_cloudwatch_alarms_high_priority[0].arn : null
    low_priority  = local.enable_alerting ? data.aws_sns_topic.mft_cloudwatch_alarms_low_priority[0].arn : null
  }
}