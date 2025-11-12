resource "aws_iam_role" "red_button_lambda_role" {
  name = "${local.application_name}-${local.environment}-red_button_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-red-button-trigger"
  })
}

resource "aws_iam_role_policy" "red_button_lambda_policy" {
  name = "${local.application_name}-${local.environment}-red_button_policy"
  role = aws_iam_role.red_button_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/${aws_lambda_function.red_button_trigger.function_name}"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroupRules",
          "ec2:DescribeSecurityGroups",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.red_button_data.arn,
          "${aws_s3_bucket.red_button_data.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_lambda_function" "red_button_trigger" {
  filename         = "./lambda/red_button_trigger.zip"
  function_name    = "${local.application_name}-${local.environment}-red-button-trigger"
  role             = aws_iam_role.red_button_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = filebase64sha256("./lambda/red_button_trigger.zip")
  runtime          = "python3.13"
  timeout          = 300

  environment {
    variables = {
      S3_BUCKET_REDBUTTON = aws_s3_bucket.red_button_data.id
      BOOM                = local.application_data.accounts[local.environment].red_button_lambda_boom
      DEBUG               = local.application_data.accounts[local.environment].red_button_lambda_debug
    }
  }

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-red-button-trigger"
  })
}

resource "aws_s3_bucket" "red_button_data" {
  bucket = "${local.application_name}-${local.environment}-red-button-data"
  # tags = merge(local.tags,
  #   { Name = lower(format("s3-bucket-%s-%s", local.application_name, local.environment)) }
  # )
  tags = merge(
    {
      Name        = "${local.application_name}-${local.environment}-red-button-data"
      Environment = local.environment
    },
    {
      "business-unit"          = "LAA",
      "infrastructure-support" = "laa-role-sre@digital.justice.gov.uk",
      "source-code"            = "https://github.com/ministryofjustice/modernisation-platform-environments"
    }
  )
}

resource "aws_s3_bucket_logging" "red_button_access_logging" {

  bucket = aws_s3_bucket.red_button_data.id

  target_bucket = local.logging_bucket_name
  target_prefix = "s3-access-logs/${local.application_name}-${local.environment}-red-button-data/"
}

resource "aws_s3_bucket_public_access_block" "red_button_data" {
  bucket                  = aws_s3_bucket.red_button_data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "red_button_data" {
  bucket = aws_s3_bucket.red_button_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "red_button_data" {
  bucket = aws_s3_bucket.red_button_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_cloudwatch_log_group" "red_button_logs" {
  name              = "/aws/lambda/${aws_lambda_function.red_button_trigger.function_name}"
  retention_in_days = 14
  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-red-button-trigger"
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "red_button_data_lifecycle" {

  bucket = aws_s3_bucket.red_button_data.id

  # One lifecycle rule per prefix
  rule {
    id = "expire-${aws_s3_bucket.red_button_data.id}-${local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_current
    }d"
    status = "Enabled"


    expiration {
      days = local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_current
    }

    noncurrent_version_transition {
      noncurrent_days = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_noncurrent_standard
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_noncurrent_glacier
      storage_class   = "GLACIER"
    }
    noncurrent_version_expiration {
      noncurrent_days = local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_noncurrent
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = local.application_data.accounts[local.environment].s3_lifecycle_days_abort_incomplete_multipart_upload_days
    }

  }

}

# Outputs
output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.red_button_trigger.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.red_button_trigger.arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for backups"
  value       = aws_s3_bucket.red_button_data.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for backups"
  value       = aws_s3_bucket.red_button_data.arn
}

output "iam_role_arn" {
  description = "ARN of the IAM role for the Lambda function"
  value       = aws_iam_role.red_button_lambda_role.arn
}