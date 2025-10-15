######################################
#####     CCMS Provider SQS     #########
######################################
resource "aws_sqs_queue" "patch_ccms_provider_dlq" {
  count                     = local.environment == "test" ? 1 : 0
  name                      = "patch_ccms_provider_dlq"
  message_retention_seconds = 1209600
  max_message_size          = 262144

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-patch-ccms-banks-dlq"
    }
  )
}

resource "aws_sqs_queue" "patch_ccms_provider_q" {
  count                      = local.environment == "test" ? 1 : 0
  name                       = "patch_ccms_provider_q.fifo"
  fifo_queue                 = true
  delay_seconds              = 90
  max_message_size           = 262144
  message_retention_seconds  = 604800
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 120

  kms_master_key_id                 = aws_kms_key.sns_sqs_key.id
  kms_data_key_reuse_period_seconds = 300

  tags = merge(
    local.tags,
    {
      Name     = "${local.application_name_short}-${local.environment}-patch-ccms-banks-q"
      Priority = "P1"
    }
  )
}