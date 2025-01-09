# ---------------------------------------
# live fms data json trigger
# ---------------------------------------
resource "aws_s3_bucket_notification" "historic_data_store" {
  depends_on = [aws_lambda_permission.historic, aws_lambda_permission.live_serco_fms]
  bucket     = module.s3-data-bucket.bucket.id

  lambda_function {
    lambda_function_arn = module.calculate_checksum.lambda_function_arn
    events = [
      "s3:ObjectCreated:*"
    ]
    filter_suffix = ".bak"
  }
  lambda_function {
    lambda_function_arn = module.calculate_checksum.lambda_function_arn
    events = [
      "s3:ObjectCreated:*",
    ]
    filter_suffix = ".zip"
  }
  lambda_function {
    lambda_function_arn = module.calculate_checksum.lambda_function_arn
    events = [
      "s3:ObjectCreated:*",
    ]
    filter_suffix = ".bacpac"
  }
  lambda_function {
    lambda_function_arn = module.format_json_fms_data.lambda_function_arn
    events = [
      "s3:ObjectCreated:*",
    ]
    filter_suffix = ".JSON"
    filter_prefix = "serco/fms/"
  }
}


resource "aws_lambda_permission" "live_serco_fms" {
  statement_id  = "LiveSercoFMSLambdaAllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.format_json_fms_data.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3-data-bucket.bucket.arn
}


# ---------------------------------------
# historic data json trigger
# ---------------------------------------

resource "aws_lambda_permission" "historic" {
  statement_id  = "ChecksumLambdaAllowExecutionFromHistoricData"
  action        = "lambda:InvokeFunction"
  function_name = module.calculate_checksum.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3-data-bucket.bucket.arn
}
