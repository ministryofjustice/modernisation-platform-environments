# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "vcms_alarms" {
  name = "vcms-${local.environment}-alarms-topic"
  tags = local.tags
}
