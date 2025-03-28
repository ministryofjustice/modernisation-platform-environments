# Cloudwatch pipeline group
resource "aws_cloudwatch_log_group" "pipeline_logs" {
  name              = "/aws/fms-pipeline/"
  retention_in_days = 30

  tags = local.tags
}

# S3 Bucket Notifications
resource "aws_s3_bucket_notification" "fms_bucket_notification" {
  bucket = module.s3-fms-general-landing-bucket.bucket.id

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
