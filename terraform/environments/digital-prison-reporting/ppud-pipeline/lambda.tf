data "aws_iam_policy_document" "copy_object" {
  statement {
    // Allow the lambda to read and copy the files from the land S3 bucket
    actions = [
      "s3:GetObject",
      "s3:GetObjectTagging",
    ]

    resources = [
      module.ppud.s3_bucket_arn,
      "${module.ppud.s3_bucket_arn}/*"
    ]
  }

  statement {
    // Allow the lambda to write the files to the bak upload S3 bucket
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging"
    ]

    resources = [
      module.rds_export.backup_uploads_s3_bucket_arn,
      "${module.rds_export.backup_uploads_s3_bucket_arn}/*"
    ]
  }
}

module "copy_object" {
  # Commit hash for v8.1.2
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda?ref=a7db1252f2c2048ab9a61254869eea061eae1318"

  function_name   = "${local.name}-${local.environment}-copy"
  description     = "Lambda to copy a file from the land bucket to bak upload bucket"
  handler         = "copy_file.handler"
  runtime         = "python3.12"
  memory_size     = 1024
  timeout         = 900
  architectures   = ["x86_64"]
  build_in_docker = false

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.copy_object.json

  environment_variables = {
    LAND_BUCKET           = module.ppud.s3_bucket_id
    BACKUP_UPLOADS_BUCKET = module.rds_export.backup_uploads_s3_bucket_id
    REGION                = data.aws_region.current.region
  }

  source_path = [{
    path = "${path.module}/lambda_functions/copy_file.py"
  }]

  tags = local.tags
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.copy_object.lambda_function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = module.ppud.s3_bucket_arn
}

# Bucket Notification to trigger Lambda function
resource "aws_s3_bucket_notification" "land_bucket" {
  bucket = module.ppud.s3_bucket_id

  lambda_function {
    lambda_function_arn = module.copy_object.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

data "aws_iam_policy_document" "check_recent_file" {
  statement {
    // Allow the lambda to list objects from the land S3 bucket
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      module.ppud.s3_bucket_arn,
    ]
  }

  statement {
    // Allow the lambda to fetch the Slack webhook secret
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      module.slack_webhook_secret.secret_arn,
    ]
  }
}

module "check_recent_file" {
  # Commit hash for v8.1.2
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda?ref=a7db1252f2c2048ab9a61254869eea061eae1318"

  function_name   = "${local.name}-${local.environment}-check-recent-file"
  description     = "Lambda to check most recent land-bucket file date and notify Slack if stale"
  handler         = "check_recent_file.handler"
  runtime         = "python3.12"
  memory_size     = 256
  timeout         = 120
  architectures   = ["x86_64"]
  build_in_docker = false

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.check_recent_file.json

  environment_variables = {
    LAND_BUCKET               = module.ppud.s3_bucket_id
    REGION                    = data.aws_region.current.region
    SLACK_WEBHOOK_SECRET_NAME = module.slack_webhook_secret.secret_id
    DAYS_BACK                 = "1"
  }

  source_path = [{
    path = "${path.module}/lambda_functions/check_recent_file.py"
  }]

  tags = local.tags
}

resource "aws_lambda_permission" "allow_eventbridge_check_recent_file" {
  statement_id  = "AllowExecutionFromEventBridgeCheckRecentFile"
  action        = "lambda:InvokeFunction"
  function_name = module.check_recent_file.lambda_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.check_recent_file_daily.arn
}

resource "aws_cloudwatch_event_rule" "check_recent_file_daily" {
  name                = "${local.name}-${local.environment}-check-recent-file-daily"
  description         = "Invoke recent-file checker daily at 07:30 UTC"
  schedule_expression = "cron(30 07 * * ? *)"
}

resource "aws_cloudwatch_event_target" "check_recent_file_daily" {
  rule      = aws_cloudwatch_event_rule.check_recent_file_daily.name
  target_id = "check-recent-file-lambda"
  arn       = module.check_recent_file.lambda_function_arn
}