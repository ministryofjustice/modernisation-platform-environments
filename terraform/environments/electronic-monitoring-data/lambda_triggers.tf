# ---------------------------------------
# live fms data json trigger
# ---------------------------------------
resource "aws_sns_topic_subscription" "live_serco_fms_sns_subscription" {
  topic_arn = aws_sns_topic.live_serco_fms_s3_events.arn
  protocol  = "sqs"
  endpoint  = module.format_json_fms_data.lambda_function_dlq_arn
}

resource "aws_lambda_permission" "live_serco_fms_with_sns" {
  statement_id  = "LiveServcoFMSLambdaAllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.format_json_fms_data.lambda_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = module.format_json_fms_data.lambda_function_dlq_arn
}


# ---------------------------------------
# historic data json trigger
# ---------------------------------------
resource "aws_sns_topic_subscription" "historic_sns_subscription" {
  topic_arn = aws_sns_topic.historic_s3_events.arn
  protocol  = "sqs"
  endpoint  = module.calculate_checksum.lambda_function_dlq_arn
}

resource "aws_lambda_permission" "historic_with_sns" {
  statement_id  = "ChecksumLambdaAllowExecutionFromHistoricDataSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.calculate_checksum.lambda_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = module.calculate_checksum.lambda_function_dlq_arn
}
