data "aws_iam_policy_document" "copy_object" {
  statement {
    // Allow the lambda to read and copy the files from the replication destination S3 bucket
    actions = [
      "s3:GetObject",
      "s3:GetObjectTagging",
    ]

    resources = [
      module.ppud_replication_destination.bucket.arn,
      "${module.ppud_replication_destination.bucket.arn}/*"
    ]
  }

  statement {
    // Allow the lambda to write the files to the rds export bak upload S3 bucket
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging"
    ]

    resources = [
      module.ppud_rds_export.backup_uploads_s3_bucket_arn,
      "${module.ppud_rds_export.backup_uploads_s3_bucket_arn}/*"
    ]
  }
}

module "copy_object" {
  # v8.8.1
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda?ref=23d00f7daef40091e87ed2f9dc5d8532e9d2cc22"

  function_name   = "${local.component_name}-copy"
  description     = "Lambda to copy a file from the bak replication destination bucket to rds export bak upload bucket"
  handler         = "copy_file.handler"
  runtime         = "python3.12"
  memory_size     = 1024
  timeout         = 900
  architectures   = ["x86_64"]
  build_in_docker = false

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.copy_object.json

  environment_variables = {
    LAND_BUCKET           = module.ppud_replication_destination.bucket.id
    BACKUP_UPLOADS_BUCKET = module.ppud_rds_export.backup_uploads_s3_bucket_id
    REGION                = data.aws_region.current.region
  }

  source_path = [{
    path = "${path.module}/lambda_functions/copy_file.py"
  }]

  tags = merge(
    local.tags,
    {
      resource-type = "Lambda"
    }
  )

}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.copy_object.lambda_function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = module.ppud_replication_destination.bucket.arn
}

# Bucket Notification to trigger Lambda function
resource "aws_s3_bucket_notification" "land_bucket" {
  bucket = module.ppud_replication_destination.bucket.id

  lambda_function {
    lambda_function_arn = module.copy_object.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

# data "aws_iam_policy_document" "check_recent_file" {
#   statement {
#     // Allow the lambda to list objects from the replication destination S3 bucket
#     actions = [
#       "s3:ListBucket",
#     ]

#     resources = [
#       module.ppud_replication_destination.bucket.arn,
#     ]
#   }

#   statement {
#     // Allow the lambda to fetch the Slack webhook secret
#     actions = [
#       "secretsmanager:GetSecretValue",
#     ]

#     resources = [
#       module.ppud_slack_webhook.secret_arn,
#     ]
#   }
# }

# module "check_recent_file" {
#   # Commit hash for v8.8.1
#   source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda?ref=23d00f7daef40091e87ed2f9dc5d8532e9d2cc22"

#   function_name   = "${local.component_name}-check-recent-file"
#   description     = "Lambda to check most recent replication destination bucket file date and notify Slack if stale"
#   handler         = "check_recent_file.handler"
#   runtime         = "python3.12"
#   memory_size     = 256
#   timeout         = 120
#   architectures   = ["x86_64"]
#   build_in_docker = false

#   attach_policy_json = true
#   policy_json        = data.aws_iam_policy_document.check_recent_file.json

#   environment_variables = {
#     LAND_BUCKET               = module.ppud_replication_destination.bucket.id
#     REGION                    = data.aws_region.current.current
#     SLACK_WEBHOOK_SECRET_NAME = module.ppud_slack_webhook.secret_id
#     DAYS_BACK                 = "1"
#   }

#   source_path = [{
#     path = "${path.module}/lambda_functions/check_recent_file.py"
#   }]

#   tags = merge(
#     local.tags,
#     {
#       resource-type = "Lambda"
#     }
#   )

# }

# resource "aws_lambda_permission" "allow_eventbridge_check_recent_file" {
#   statement_id  = "AllowExecutionFromEventBridgeCheckRecentFile"
#   action        = "lambda:InvokeFunction"
#   function_name = module.check_recent_file.lambda_function_arn
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.check_recent_file_daily.arn
# }

# resource "aws_cloudwatch_event_rule" "check_recent_file_daily" {
#   name                = "${local.component_name}-check-recent-file-daily"
#   description         = "Invoke recent-file checker daily at 15:15 UTC"
#   schedule_expression = "cron(15 15 * * ? *)"
# }

# resource "aws_cloudwatch_event_target" "check_recent_file_daily" {
#   rule      = aws_cloudwatch_event_rule.check_recent_file_daily.name
#   target_id = "check-recent-file-lambda"
#   arn       = module.check_recent_file.lambda_function_arn
# }
