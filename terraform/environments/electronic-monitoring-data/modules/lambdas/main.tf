locals {
  use_vpc_config = !(var.security_group_ids == null || var.subnet_ids == null)
  function_uri   = var.function_tag != null ? var.function_tag : (var.is_image ? (var.image_name != null ? "${var.image_name}-${var.production_dev}" : "${var.function_name}-${var.production_dev}") : "")
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_sqs_queue" "lambda_dlq" {
  name              = "${var.function_name}-dlq"
  kms_master_key_id = aws_kms_key.lambda_env_key.id
}

data "external" "empty_bash_script" {
  for_each = var.is_image ? { image = 1 } : {} # Use empty map if not fetching image

  program = ["bash", "bash_scripts/empty_bash.sh"]
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access_execution" {
  role       = var.role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_queue_access_execution" {
  role       = var.role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}


resource "aws_kms_key" "lambda_env_key" {
  description         = "KMS key for encrypting Lambda environment variables for ${var.function_name}"
  enable_key_rotation = true

  policy = <<EOF
{
  "Id": "key-default",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Enable log service Permissions",
      "Effect": "Allow",
      "Principal": {
        "Service": "logs.eu-west-2.amazonaws.com"
      },
      "Action": [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_dlq_policy" {
  name        = "${var.function_name}-dlq-policy"
  description = "Policy for Lambda to use DLQ for ${var.function_name}"

  policy = data.aws_iam_policy_document.lambda_dlq_policy.json
}


data "aws_iam_policy_document" "lambda_dlq_policy" {
  statement {
    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl"
    ]
    resources = [aws_sqs_queue.lambda_dlq.arn]
  }
}

resource "aws_iam_policy" "lambda_kms_policy" {
  name        = "${var.function_name}-kms-policy"
  description = "Policy for Lambda to use KMS key for ${var.function_name}"

  policy = data.aws_iam_policy_document.lambda_kms_policy.json
}

data "aws_iam_policy_document" "lambda_kms_policy" {
  statement {
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [aws_kms_key.lambda_env_key.arn]
  }
}

resource "aws_iam_policy" "lambda_xray_policy" {
  name        = "${var.function_name}-xray-policy"
  description = "Policy for Lambda to use X-Ray for ${var.function_name}"

  policy = data.aws_iam_policy_document.lambda_xray_policy.json
}

data "aws_iam_policy_document" "lambda_xray_policy" {
  statement {
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords"
    ]
    resources = ["*"]
  }
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


resource "aws_cloudwatch_log_group" "lambda_cloudwatch_group" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 400
  kms_key_id        = aws_kms_key.lambda_env_key.arn
}

# Create a null_resource to zip the file and upload it to S3
resource "null_resource" "zip_and_upload" {
  count = var.is_image ? 0 : 1
  provisioner "local-exec" {
    command = <<EOT
      zip -j ${var.filename}.zip ${var.filename}
      aws s3 cp ${var.filename}.zip s3://${var.s3_bucket}/${var.filename}
    EOT
    environment = {
      AWS_DEFAULT_REGION = data.aws_region.current.name
    }
  }

  triggers = {
    source_file_hash = filesha256(var.filename)
  }
}

resource "aws_lambda_function" "this" {
  #checkov:skip=CKV_AWS_272:Lambda needs code-signing, see ELM-1975
  # Zip File config
  s3_bucket        = var.is_image ? null : var.s3_bucket
  s3_key           = var.is_image ? null : var.filename
  filename         = var.is_image ? null : var.filename
  handler          = var.is_image ? null : var.handler
  layers           = var.is_image ? null : var.layers
  source_code_hash = var.is_image ? null : var.source_code_hash
  runtime          = var.is_image ? null : var.runtime
  # Image config
  image_uri    = var.is_image ? "${var.core_shared_services_id}.dkr.ecr.eu-west-2.amazonaws.com/${var.ecr_repo_name}:${local.function_uri}" : null
  package_type = var.is_image ? "Image" : null
  # Constants
  function_name = var.function_name
  role          = var.role_arn
  timeout       = var.timeout
  memory_size   = var.memory_size

  ephemeral_storage {
    size = var.ephemeral_storage_size # Min 512 MB and the Max 10240 MB
  }

  dynamic "vpc_config" {
    for_each = local.use_vpc_config ? [1] : []
    content {
      security_group_ids = var.security_group_ids
      subnet_ids         = var.subnet_ids
    }
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
  reserved_concurrent_executions = var.reserved_concurrent_executions

}
