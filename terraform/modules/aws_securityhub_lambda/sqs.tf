resource "aws_sqs_queue" "securityhub_findings_dlq" {
  name                              = "${var.project_name}-securityhub-findings-dlq"
  message_retention_seconds         = 1209600
  visibility_timeout_seconds        = 30
  kms_master_key_id                 = aws_kms_key.securityhub.key_id
  kms_data_key_reuse_period_seconds = 300
}
