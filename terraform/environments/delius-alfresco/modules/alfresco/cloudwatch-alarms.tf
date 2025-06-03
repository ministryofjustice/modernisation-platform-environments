# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "alfresco_alerting" {
  name              = "${var.app_name}-alerting"
  kms_master_key_id = var.account_config.kms_keys.general_shared
}