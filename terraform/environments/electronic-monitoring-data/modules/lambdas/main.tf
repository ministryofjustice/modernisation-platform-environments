resource "aws_sqs_queue" "lambda_dlq" {
  name = "${var.function_name}-dlq"
}

resource "aws_kms_key" "lambda_env_key" {
  description = "KMS key for encrypting Lambda environment variables for ${var.function_name}"
}

resource "aws_kms_alias" "lambda_env_alias" {
  name          = "alias/${var.function_name}-env-key"
  target_key_id = aws_kms_key.lambda_env_key.id
}

resource "aws_signer_signing_profile" "example" {
  name       = "${var.function_name}-signing-profile"
  platform_id = "AWSLambda-SHA384-ECDSA"
}

resource "aws_lambda_code_signing_config" "example" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.example.arn]
  }
  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }
}

resource "aws_iam_policy" "lambda_dlq_policy" {
  name        = "${var.function_name}-dlq-policy"
  description = "Policy for Lambda to use DLQ and Code Signing for ${var.function_name}"
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
      },
      {
        Effect = "Allow",
        Action = [
          "signer:StartSigningJob",
          "signer:GetSigningProfile",
          "signer:DescribeSigningJob"
        ],
        Resource = aws_signer_signing_profile.example.arn
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

  kms_key_arn = aws_kms_alias.lambda_env_alias.arn

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  code_signing_config_arn = aws_lambda_code_signing_config.example.arn
}
