module "firehose_cloudwatch_log_group" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-cloudwatch.git//modules/log-group?ref=82e5143738712a283ab7a8cb4110e7a3e708a834" # v5.7.3

  name              = "/aws/kinesisfirehose/${local.component_name}"
  kms_key_id        = module.destination_kms_key[0].key_arn
  retention_in_days = 400
}

resource "aws_cloudwatch_log_stream" "firehose" {
  count = local.is-production ? 1 : 0

  name           = "S3Delivery"
  log_group_name = module.firehose_cloudwatch_log_group[0].cloudwatch_log_group_name
}
