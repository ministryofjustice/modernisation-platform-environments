resource "aws_sqs_queue" "github_workflow_dlq" {
  name                              = "${var.project_name}-github-workflow-dlq"
  message_retention_seconds         = 1209600
  visibility_timeout_seconds        = 30
  kms_master_key_id                 = aws_kms_key.lambda.key_id
  kms_data_key_reuse_period_seconds = 300
}
