
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


# Create deployment package for the Lambda function.
data "archive_file" "quarantine_lambda" {
  type        = "zip"
  source_dir = "${path.module}/src"
  output_path = "${path.module}/lambda.zip"
}

# Create the Lambda function.
resource "aws_lambda_function" "quarantine" {
  function_name = var.name

  # Lambda assumes the IAM role created in iam.tf
  role    = aws_iam_role.quarantine_lambda.arn

  handler = var.lambda_handler
  runtime = var.runtime

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
