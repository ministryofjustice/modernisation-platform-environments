data "aws_sns_topic" "mft_cloudwatch_alarms_high_priority" {
  count = local.enable_alerting ? 1 : 0
  name  = "integration-hub-managed-file-transfer-cloudwatch-alarms-high-priority"
}

data "aws_sns_topic" "mft_cloudwatch_alarms_low_priority" {
  count = local.enable_alerting ? 1 : 0
  name  = "integration-hub-managed-file-transfer-cloudwatch-alarms-low-priority"
}
