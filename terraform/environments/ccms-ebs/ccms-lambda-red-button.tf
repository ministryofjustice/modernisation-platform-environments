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
          module.red_button_data.arn,
          "${module.red_button_data.arn}/*"
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
      S3_BUCKET_REDBUTTON = module.red-button-data.id
      BOOM                = local.application_data.accounts[local.environment].red_button_lambda_boom
      DEBUG               = local.application_data.accounts[local.environment].red_button_lambda_debug
    }
  }

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-red-button-trigger"
  })
}

module "red-button-data" { #tfsec:ignore:aws-s3-enable-versioning
  # v8.2.0 = https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket/commit/52a40b0dd18aaef0d7c5565d93cc8997aad79636
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=52a40b0dd18aaef0d7c5565d93cc8997aad79636"

  bucket_name = "${local.application_name}-${local.environment}-red-button-data"
  sse_algorithm      = "AES256"
  custom_kms_key     = ""
  #  bucket_prefix      = "s3-bucket-example"
  versioning_enabled = true
  bucket_policy      = [data.aws_iam_policy_document.artefacts_s3_policy.json]

  log_bucket = local.logging_bucket_name
  log_prefix = "s3access/${local.application_name}-${local.environment}-red-button-data"

  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below three variables and providers configuration are only relevant if 'replication_enabled' is set to true
  replication_region = "eu-west-2"
  # replication_role_arn                     = module.s3-bucket-replication-role.role.arn
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_current_standard
          storage_class = "STANDARD_IA"
          }, {
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_current_glacier
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_current
      }

      noncurrent_version_transition = [
        {
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_noncurrent_standard
          storage_class = "STANDARD_IA"
          }, {
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_noncurrent_glacier
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_noncurrent
      }

      abort_incomplete_multipart_upload_days = local.application_data.accounts[local.environment].s3_lifecycle_days_abort_incomplete_multipart_upload_days
    }
  ]

  tags = merge(local.tags,
    { Name = lower(format("s3-bucket-%s-%s", local.application_name, local.environment)) }
  )
}
resource "aws_s3_bucket_notification" "artefact_bucket_notification" {
  bucket = module.s3-bucket.bucket.id
  eventbridge = true
  topic {
    topic_arn     = aws_sns_topic.s3_topic.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}

data "aws_iam_policy_document" "artefacts_s3_policy" {
  statement {
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/developer",
        "arn:aws:iam::${local.environment_management.account_ids["core-shared-services-production"]}:root"
      ]
    }
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${local.artefact_bucket_name}/*"]
  }
}


# resource "aws_s3_bucket" "red_button_data" {
#   bucket = "${local.application_name}-${local.environment}-red-button-data"
# }

# resource "aws_s3_bucket_public_access_block" "red_button_data" {
#   bucket                  = aws_s3_bucket.red_button_data.id
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# resource "aws_s3_bucket_versioning" "red_button_data" {
#   bucket = aws_s3_bucket.red_button_data.id

#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "red_button_data" {
#   bucket = aws_s3_bucket.red_button_data.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

resource "aws_cloudwatch_log_group" "red_button_logs" {
  name              = "/aws/lambda/${aws_lambda_function.red_button_trigger.function_name}"
  retention_in_days = 14
  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-red-button-trigger"
  })
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
  value       = module.red-button-data.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for backups"
  value       = module.red-button-data.arn
}

output "iam_role_arn" {
  description = "ARN of the IAM role for the Lambda function"
  value       = aws_iam_role.red_button_lambda_role.arn
}