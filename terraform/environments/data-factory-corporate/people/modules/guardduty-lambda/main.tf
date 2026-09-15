
#  Lambda function that moves failed or infected objects into the quarantine bucket.
#
# The Lambda is triggered by EventBridge.
#
# Intended flow:
#
# 1. Object is uploaded to the raw bucket.
# 2. GuardDuty scans the object.
# 3. GuardDuty publishes the scan result to EventBridge.
# 4. EventBridge invokes this Lambda for bad scan results.

# Create Dead Letter Queue
resource "aws_sqs_queue" "quarantine_dlq" {
  name                  = "${var.name}-dlq"
  kms_master_key_id     = var.lambda_kms_key_arn
  tags                  = local.common_tags
}

# Create deployment package for the Lambda function.
data "archive_file" "quarantine_lambda" {
  type        = "zip"
  source_dir = "${path.module}/src"
  output_path = "${path.module}/lambda.zip"
}

# Create the Lambda function.
resource "aws_lambda_function" "quarantine" {
  # checkov:skip=CKV_AWS_117: Lambda does not need VPC access; it only uses S3 and KMS APIs
  # checkov:skip=CKV_AWS_272: Code signing is not used for this small internal Lambda package
  dead_letter_config {
    target_arn = aws_sqs_queue.quarantine_dlq.arn
  }
  function_name = var.name

  # Lambda assumes the IAM role created in iam.tf
  role    = aws_iam_role.quarantine_lambda.arn

  reserved_concurrent_executions = var.reserved_concurrent_executions

  tracing_config {
    mode = "Active"
  }

  handler = var.lambda_handler
  runtime = var.runtime

  kms_key_arn = var.lambda_kms_key_arn

  filename         = data.archive_file.quarantine_lambda.output_path
  source_code_hash = data.archive_file.quarantine_lambda.output_base64sha256

  timeout     = var.timeout
  memory_size = var.memory_size

  environment {
    variables = {
      QUARANTINE_BUCKET_NAME = var.quarantine_bucket_name
      QUARANTINE_KMS_KEY_ARN = var.quarantine_kms_key_arn
      QUARANTINE_STATUSES = jsonencode(var.quarantine_statuses)
    }
  }

  tags = local.common_tags
}
