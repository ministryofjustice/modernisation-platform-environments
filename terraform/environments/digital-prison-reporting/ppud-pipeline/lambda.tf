data "aws_iam_policy_document" "ppud_copy_object" {
  count = local.is-test ? 0 : 1
  statement {
    // Allow the lambda to read and copy the files from the replication destination S3 bucket
    actions = [
      "s3:GetObject",
      "s3:GetObjectTagging",
    ]

    resources = [
      module.ppud_replication_destination[0].bucket.arn,
      "${module.ppud_replication_destination[0].bucket.arn}/*"
    ]
  }

  statement {
    // Allow the lambda to write the files to the rds export bak upload S3 bucket
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging"
    ]

    resources = [
      module.ppud_rds_export[0].backup_uploads_s3_bucket_arn,
      "${module.ppud_rds_export[0].backup_uploads_s3_bucket_arn}/*"
    ]
  }

}

# Copy replicated .bak ppud file from replication destination bucket to landing bucket
module "ppud_copy_object" {
  count = local.is-test ? 0 : 1

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
  policy_json        = data.aws_iam_policy_document.ppud_copy_object[0].json

  environment_variables = {
    LAND_BUCKET           = module.ppud_replication_destination[0].bucket.id
    BACKUP_UPLOADS_BUCKET = module.ppud_rds_export[0].backup_uploads_s3_bucket_id
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

# Grants permission for lambda to be invoked from S3 
resource "aws_lambda_permission" "ppud_allow_bucket" {
  count = local.is-test ? 0 : 1

  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.ppud_copy_object[0].lambda_function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = module.ppud_replication_destination[0].bucket.arn
}

# Bucket Notification to trigger Lambda function
resource "aws_s3_bucket_notification" "ppud_land_bucket" {
  count = local.is-test ? 0 : 1

  bucket = module.ppud_replication_destination[0].bucket.id

  lambda_function {
    lambda_function_arn = module.ppud_copy_object[0].lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.ppud_allow_bucket]
}

data "aws_iam_policy_document" "check_recent_file" {
  count = local.is-development ? 1 : 0
  statement {
    // Allow the lambda to list objects from the replication destination S3 bucket
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      module.ppud_replication_destination[0].bucket.arn,
    ]
  }

  statement {
    // Allow the lambda to fetch the Slack webhook secret
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      module.ppud_slack_webhook[0].secret_arn,
    ]
  }

  statement {
    // Allow the lambda to decrypt the Slack webhook secret using the KMS key
    actions = [
      "kms:Decrypt",
    ]

    resources = [
      module.ppud_kms[0].key_arn,
    ]
  }
}

module "check_recent_file" {
  count = local.is-development ? 1 : 0

  # Commit hash for v8.8.1
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda?ref=23d00f7daef40091e87ed2f9dc5d8532e9d2cc22"

  function_name   = "${local.component_name}-check-recent-file"
  description     = "Lambda to check most recent replication destination bucket file date and notify Slack if stale"
  handler         = "check_recent_file.handler"
  runtime         = "python3.12"
  memory_size     = 256
  timeout         = 120
  architectures   = ["x86_64"]
  build_in_docker = false

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.check_recent_file[0].json

  environment_variables = {
    LAND_BUCKET               = module.ppud_replication_destination[0].bucket.id
    REGION                    = data.aws_region.current.region
    SLACK_WEBHOOK_SECRET_NAME = module.ppud_slack_webhook[0].secret_id
    DAYS_BACK                 = local.days_back
  }

  source_path = [{
    path = "${path.module}/lambda_functions/check_recent_file.py"
  }]

  tags = merge(
    local.tags,
    {
      resource-type = "Lambda"
    }
  )

}

resource "aws_lambda_permission" "allow_eventbridge_check_recent_file" {
  count         = local.is-development ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridgeCheckRecentFile"
  action        = "lambda:InvokeFunction"
  function_name = module.check_recent_file[0].lambda_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.check_recent_file_daily[0].arn
}

resource "aws_cloudwatch_event_rule" "check_recent_file_daily" {
  count               = local.is-development ? 1 : 0
  name                = "${local.component_name}-check-recent-file-daily"
  description         = "Invoke recent-file checker daily at 15:15 UTC"
  schedule_expression = local.cron_schedule
}

resource "aws_cloudwatch_event_target" "check_recent_file_daily" {
  count     = local.is-development ? 1 : 0
  rule      = aws_cloudwatch_event_rule.check_recent_file_daily[0].name
  target_id = "check-recent-file-lambda"
  arn       = module.check_recent_file[0].lambda_function_arn
}
