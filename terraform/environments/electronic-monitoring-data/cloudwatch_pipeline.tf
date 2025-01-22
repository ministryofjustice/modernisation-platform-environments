# Cloudwatch pipeline group
resource "aws_cloudwatch_log_group" "pipeline_logs" {
  name              = "/aws/fms-pipeline/"
  retention_in_days = 30

  tags = local.tags
}

# S3 Bucket Notifications
resource "aws_s3_bucket_notification" "bucket_1_notification" {
  bucket = aws_s3_bucket.input_bucket_1.id

  lambda_function {
    lambda_function_arn = module.event_logger.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_s3_bucket_notification" "bucket_2_notification" {
  bucket = aws_s3_bucket.input_bucket_2.id

  lambda_function {
    lambda_function_arn = module.event_logger.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }
}

# CloudWatch Event Rule for Summary Generator
resource "aws_cloudwatch_event_rule" "daily_summary" {
  name                = "daily-pipeline-summary-fms"
  description         = "Triggers pipeline summary generation daily"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "summary_generator" {
  rule      = aws_cloudwatch_event_rule.daily_summary.name
  target_id = "SummaryGenerator"
  arn       = module.summary_generator.lambda_function_arn
}
