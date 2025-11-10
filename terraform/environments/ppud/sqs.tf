##########################################
# SQS Lambda Queues and Dead Letter Queues
##########################################

data "aws_sqs_queue" "lambda_dead_letter_queue" {
  name = "lambda_dead_letter_queue"
}

resource "aws_sqs_queue" "lambda_function_queue" {
  # checkov:skip=CKV_AWS_27: "SQS queue encryption is not required as no sensitive data is processed through it"
  name                      = "lambda_function_queue"
  message_retention_seconds = 86400 # Retain messages for 1 day
  delay_seconds             = 90
  max_message_size          = 2048
  receive_wait_time_seconds = 10
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.lambda_function_dead_letter_queue.arn
    maxReceiveCount     = 4
  })
}

resource "aws_sqs_queue" "lambda_function_dead_letter_queue" {
  # checkov:skip=CKV_AWS_27: "SQS queue encryption is not required as no sensitive data is processed through it"
  name  = "lambda_function_dead_letter_queue"
}

resource "aws_sqs_queue_redrive_allow_policy" "lambda_function_queue_redrive_allow_policy" {
  queue_url = aws_sqs_queue.lambda_function_dead_letter_queue.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.lambda_function_queue.arn]
  })
}

########################
# Production Environment
########################

resource "aws_sqs_queue" "lambda_queue_prod" {
  # checkov:skip=CKV_AWS_27: "SQS queue encryption is not required as no sensitive data is processed through it"
  count                     = local.is-production == true ? 1 : 0
  name                      = "Lambda-Queue-Production"
  message_retention_seconds = 86400 # Retain messages for 1 day
  delay_seconds             = 90
  max_message_size          = 2048
  receive_wait_time_seconds = 10
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.lambda_deadletter_queue_prod[0].arn
    maxReceiveCount     = 4
  })
}

resource "aws_sqs_queue" "lambda_deadletter_queue_prod" {
  # checkov:skip=CKV_AWS_27: "SQS queue encryption is not required as no sensitive data is processed through it"
  count = local.is-production == true ? 1 : 0
  name  = "Lambda-Deadletter-Queue-Production"
}

resource "aws_sqs_queue_redrive_allow_policy" "lambda_queue_redrive_allow_policy_prod" {
  count     = local.is-production == true ? 1 : 0
  queue_url = aws_sqs_queue.lambda_deadletter_queue_prod[0].id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.lambda_queue_prod[0].arn]
  })
}

###########################
# Preproduction Environment
###########################

resource "aws_sqs_queue" "lambda_queue_uat" {
  # checkov:skip=CKV_AWS_27: "SQS queue encryption is not required as no sensitive data is processed through it"
  count                     = local.is-preproduction == true ? 1 : 0
  name                      = "Lambda-Queue-UAT"
  message_retention_seconds = 86400 # Retain messages for 1 day
  delay_seconds             = 90
  max_message_size          = 2048
  receive_wait_time_seconds = 10
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.lambda_deadletter_queue_uat[0].arn
    maxReceiveCount     = 4
  })
}

resource "aws_sqs_queue" "lambda_deadletter_queue_uat" {
  # checkov:skip=CKV_AWS_27: "SQS queue encryption is not required as no sensitive data is processed through it"
  count = local.is-preproduction == true ? 1 : 0
  name  = "Lambda-Deadletter-Queue-UAT"
}

resource "aws_sqs_queue_redrive_allow_policy" "lambda_queue_redrive_allow_policy_uat" {
  count     = local.is-preproduction == true ? 1 : 0
  queue_url = aws_sqs_queue.lambda_deadletter_queue_uat[0].id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.lambda_queue_uat[0].arn]
  })
}

#########################
# Development Environment
#########################

resource "aws_sqs_queue" "lambda_queue_dev" {
  # checkov:skip=CKV_AWS_27: "SQS queue encryption is not required as no sensitive data is processed through it"
  count                     = local.is-development == true ? 1 : 0
  name                      = "Lambda-Queue-DEV"
  message_retention_seconds = 86400 # Retain messages for 1 day
  delay_seconds             = 90
  max_message_size          = 2048
  receive_wait_time_seconds = 10
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.lambda_deadletter_queue_dev[0].arn
    maxReceiveCount     = 4
  })
}

resource "aws_sqs_queue" "lambda_deadletter_queue_dev" {
  # checkov:skip=CKV_AWS_27: "SQS queue encryption is not required as no sensitive data is processed through it"
  count = local.is-development == true ? 1 : 0
  name  = "Lambda-Deadletter-Queue-DEV"
}

resource "aws_sqs_queue_redrive_allow_policy" "lambda_queue_redrive_allow_policy_dev" {
  count     = local.is-development == true ? 1 : 0
  queue_url = aws_sqs_queue.lambda_deadletter_queue_dev[0].id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.lambda_queue_dev[0].arn]
  })
}