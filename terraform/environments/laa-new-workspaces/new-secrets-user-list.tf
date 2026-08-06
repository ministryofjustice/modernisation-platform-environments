##############################################
### Secrets Manager — User List
###
### Stores declarative JSON list of WorkSpaces users.
### Updated manually via AWS CLI or Console.
### Changes trigger EventBridge → user lifecycle Lambda.
##############################################

resource "aws_secretsmanager_secret" "user_list" {

  name                    = "${local.application_name}/${local.environment}/user-list"
  description             = "Declarative list of WorkSpaces users. Update to trigger automatic create/delete."
  recovery_window_in_days = 0

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}/${local.environment}/user-list" }
  )
}

# Initial empty user list — content managed manually, ignore_changes prevents Terraform overwriting it
resource "aws_secretsmanager_secret_version" "user_list_initial" {

  secret_id     = aws_secretsmanager_secret.user_list.id
  secret_string = jsonencode({ users = [] })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

##############################################
### S3 Bucket for CloudTrail Logs
##############################################

resource "aws_s3_bucket" "cloudtrail" {

  bucket = "${local.application_name}-${local.environment}-cloudtrail-logs"

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-cloudtrail-logs" }
  )
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {

  bucket                  = aws_s3_bucket.cloudtrail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {

  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail" {

  bucket = aws_s3_bucket.cloudtrail.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {

  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {

  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

##############################################
### CloudTrail — Secrets Manager Events
###
### Required for EventBridge to receive PutSecretValue events.
### Without CloudTrail, Secrets Manager API calls are not
### visible to EventBridge.
##############################################

resource "aws_cloudtrail" "secrets_manager" {

  name                          = "${local.application_name}-${local.environment}-secretsmanager-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = false
  is_multi_region_trail         = false
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "WriteOnly"
    include_management_events = true
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail]

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-secretsmanager-trail" }
  )
}

##############################################
### EventBridge Rule — User List Updates
##############################################

resource "aws_cloudwatch_event_rule" "user_list_update" {

  name        = "${local.application_name}-${local.environment}-user-list-update"
  description = "Trigger user lifecycle Lambda when user list secret is updated"

  event_pattern = jsonencode({
    source      = ["aws.secretsmanager"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = ["PutSecretValue"]
      requestParameters = {
        secretId = [aws_secretsmanager_secret.user_list.arn]
      }
    }
  })

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-user-list-update" }
  )
}

resource "aws_cloudwatch_event_target" "user_list_update" {

  rule      = aws_cloudwatch_event_rule.user_list_update.name
  target_id = "UserLifecycleLambda"
  arn       = aws_lambda_function.user_lifecycle.arn
}

resource "aws_lambda_permission" "eventbridge_user_lifecycle" {

  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user_lifecycle.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.user_list_update.arn
}

##############################################
### Outputs
##############################################

output "user_list_secret_arn" {
  value       = local.environment == "development" ? aws_secretsmanager_secret.user_list.arn : null
  description = "ARN of the user list secret"
}

output "user_list_update_command" {
  value       = local.environment == "development" ? "aws secretsmanager put-secret-value --secret-id ${aws_secretsmanager_secret.user_list.arn} --secret-string '{\"users\":[{\"username\":\"Bob.Smith\",\"firstname\":\"Bob\",\"lastname\":\"Smith\",\"email\":\"bob.smith@justice.gov.uk\"}]}' --region ${local.application_data.accounts[local.environment].region}" : null
  description = "Example command to update the user list"
}
