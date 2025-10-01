######################################
########     MAAT SQS     ############
######################################
resource "aws_sqs_queue" "maat_provider_dlq" {
  name                      = "maat_provider_dlq"
  message_retention_seconds = 1209600
  max_message_size          = 262144

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-maat-provider-dlq"
    }
  )
}

resource "aws_sqs_queue" "maat_provider_q" {
  name                       = "maat_provider_q.fifo"
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
      Name     = "${local.application_name_short}-${local.environment}-maat-provider-q"
      Priority = "P1"
    }
  )
}

######################################
########     CCLF SQS     ############
######################################
resource "aws_sqs_queue" "cclf_provider_dlq" {
  name                      = "cclf_provider_dlq"
  message_retention_seconds = 1209600
  max_message_size          = 262144

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-cclf-provider-dlq"
    }
  )
}

resource "aws_sqs_queue" "cclf_provider_q" {
  name                       = "cclf_provider_q.fifo"
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
      Name     = "${local.application_name_short}-${local.environment}-cclf-provider-q"
      Priority = "P1"
    }
  )
}

######################################
########     CCR SQS     ############
######################################
resource "aws_sqs_queue" "ccr_provider_dlq" {
  name                      = "ccr_provider_dlq"
  message_retention_seconds = 1209600
  max_message_size          = 262144

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-ccr-provider-dlq"
    }
  )
}

resource "aws_sqs_queue" "ccr_provider_q" {
  name                       = "ccr_provider_q.fifo"
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
      Name     = "${local.application_name_short}-${local.environment}-ccr-provider-q"
      Priority = "P1"
    }
  )
}

######################################
#####     CCMS Provider SQS     #########
######################################
resource "aws_sqs_queue" "ccms_provider_dlq" {
  name                      = "ccms_provider_dlq"
  message_retention_seconds = 1209600
  max_message_size          = 262144

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-ccms-banks-dlq"
    }
  )
}

resource "aws_sqs_queue" "ccms_provider_q" {
  name                       = "ccms_provider_q.fifo"
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
      Name     = "${local.application_name_short}-${local.environment}-ccms-banks-q"
      Priority = "P1"
    }
  )
}