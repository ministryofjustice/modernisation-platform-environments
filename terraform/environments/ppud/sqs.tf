# Lambda Queue and Dead Letter Queue

resource "aws_sqs_queue" "lambda_queue_prod" {
  count                     = local.is-production == true ? 1 : 0
  name                      = "Lambda-Queue-Production"
  message_retention_seconds = 86400  # Retain messages for 1 day
  delay_seconds             = 90
  max_message_size          = 2048
  receive_wait_time_seconds = 10
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.lambda_deadletter_queue_prod.arn
    maxReceiveCount     = 4
  })
}

resource "aws_sqs_queue" "lambda_deadletter_queue_prod" {
  count         = local.is-production == true ? 1 : 0
  name          = "Lambda-Deadletter-Queue-Production"
}

resource "aws_sqs_queue_redrive_allow_policy" "lambda_queue_redrive_allow_policy" {
  count         = local.is-production == true ? 1 : 0
  queue_url     = aws_sqs_queue.lambda_dead_letter_queue_prod.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.lambda_queue_prod.arn]
  })
}
