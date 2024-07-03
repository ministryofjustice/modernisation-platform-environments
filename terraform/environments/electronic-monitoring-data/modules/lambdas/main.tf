locals {
  use_vpc_config = !(var.security_group_ids == null || var.subnet_ids == null)
  refresh_lambda_dependencies = var.is_image ? [null_resource.image_refresh_trigger[0]] : []
}

resource "aws_sqs_queue" "lambda_dlq" {
  name              = "${var.function_name}-dlq"
  kms_master_key_id = aws_kms_key.lambda_env_key.id
}

data "external" "empty_bash_script" {
  for_each = var.is_image ? { image = 1 } : {} # Use empty map if not fetching image

  program = ["bash", "bash_scripts/empty_bash.sh"]
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
        "AWS": "arn:aws:iam::${var.env_account_id}:root"
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


resource "null_resource" "image_refresh_trigger" {
  count = var.is_image ? 1 : 0

  triggers = {
    always_run = "${md5("${timestamp()}-${random_id.unique_id.hex}")}"
  }

  provisioner "local-exec" {
    command = "echo Force refresh for Lambda function"
  }
}

resource "random_id" "unique_id" {
  byte_length = 8
}

resource "aws_lambda_function" "this" {
  # Zip File config
  filename         = var.is_image ? null : var.filename
  handler          = var.is_image ? null : var.handler
  layers           = var.is_image ? null : var.layers
  source_code_hash = var.is_image ? null : var.source_code_hash
  runtime          = var.is_image ? null : var.runtime
  # Image config
  image_uri        = var.is_image ? "${var.core_shared_services_id}.dkr.ecr.eu-west-2.amazonaws.com/electronic-monitoring-data-lambdas:${var.function_name}-${var.production_dev}" : null
  package_type     = var.is_image ? "Image" : "Zip"

  # Constants
  function_name    = var.function_name
  role             = var.role_arn
  timeout          = var.timeout
  memory_size      = var.memory_size

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
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [source_code_hash, filename, handler, layers, runtime, image_uri, package_type]
    replace_triggered_by  = [null_resource.image_refresh_trigger]
  }
}