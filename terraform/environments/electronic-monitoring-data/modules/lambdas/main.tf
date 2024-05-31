resource "aws_sqs_queue" "lambda_dlq" {
  name = "${var.function_name}-dlq"
  kms_master_key_id  = aws_kms_key.lambda_env_key.id
}

resource "aws_kms_key" "lambda_env_key" {
  description = "KMS key for encrypting Lambda environment variables for ${var.function_name}"
  enable_key_rotation     = true
}

resource "aws_iam_policy" "lambda_dlq_policy" {
  name        = "${var.function_name}-dlq-policy"
  description = "Policy for Lambda to use DLQ for ${var.function_name}"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ],
        Resource = aws_sqs_queue.lambda_dlq.arn
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_kms_policy" {
  name        = "${var.function_name}-kms-policy"
  description = "Policy for Lambda to use KMS key for ${var.function_name}"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ],
        Resource = aws_kms_key.lambda_env_key.arn
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_xray_policy" {
  name        = "${var.function_name}-xray-policy"
  description = "Policy for Lambda to use X-Ray for ${var.function_name}"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dlq_policy_attachment" {
  role       = var.role_name
  policy_arn = aws_iam_policy.lambda_dlq_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_kms_policy_attachment" {
  role       = var.role_name
  policy_arn = aws_iam_policy.lambda_kms_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_xray_policy_attachment" {
  role       = var.role_name
  policy_arn = aws_iam_policy.lambda_xray_policy.arn
}

#checkov:skip=CKV_AWS_272
resource "aws_lambda_function" "this" {
  filename         = var.filename
  function_name    = var.function_name
  role             = var.role_arn
  handler          = var.handler
  layers           = var.layers
  source_code_hash = var.source_code_hash
  timeout          = var.timeout
  memory_size      = var.memory_size
  runtime          = var.runtime

  vpc_config {
    security_group_ids = var.security_group_ids
    subnet_ids         = var.subnet_ids
  }

  environment {
    variables = var.environment_variables
  }

  kms_key_arn = aws_kms_key.lambda_env_key.arn

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

}
