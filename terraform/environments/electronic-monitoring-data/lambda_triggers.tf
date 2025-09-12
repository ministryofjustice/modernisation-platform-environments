# ---------------------------------------
# Data bucket notification triggers
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
    lambda_function_arn = module.calculate_checksum.lambda_function_arn
    events = [
      "s3:ObjectCreated:*",
    ]
    filter_suffix = ".7z"
  }
  lambda_function {
    lambda_function_arn = module.format_json_fms_data.lambda_function_arn
    events = [
      "s3:ObjectCreated:*",
    ]
    filter_suffix = ".JSON"
    filter_prefix = "serco/fms/"
  }
  lambda_function {
    lambda_function_arn = module.copy_mdss_data.lambda_function_arn
    events = [
      "s3:ObjectCreated:*",
    ]
    filter_suffix = ".jsonl"
    filter_prefix = "allied/mdss/"
  }
}

# ---------------------------------------
# mdss data jsonl lambda trigger
# ---------------------------------------

resource "aws_lambda_permission" "live_allied_mdss" {
  statement_id  = "LiveSercoFMSLambdaAllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.copy_mdss_data.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3-data-bucket.bucket.arn
}

# ---------------------------------------
# fms data JSON lambda trigger
# ---------------------------------------

resource "aws_lambda_permission" "live_serco_fms" {
  statement_id  = "LiveSercoFMSLambdaAllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.format_json_fms_data.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3-data-bucket.bucket.arn
}

# ---------------------------------------
# historic data checksum trigger
# ---------------------------------------

resource "aws_lambda_permission" "historic" {
  statement_id  = "ChecksumLambdaAllowExecutionFromHistoricData"
  action        = "lambda:InvokeFunction"
  function_name = module.calculate_checksum.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3-data-bucket.bucket.arn
}


# --------------------------------------------------------
# Trigger airflow notification
# --------------------------------------------------------

resource "aws_s3_bucket_notification" "raw_formatted_data_bucket" {
  count = local.is-development ? 0 : 1

  depends_on = [aws_lambda_permission.airflow_allied_mdss]
  bucket     = module.s3-raw-formatted-data-bucket.bucket.id

  lambda_function {
    lambda_function_arn = module.airflow_trigger[0].lambda_function_arn
    events = [
      "s3:ObjectCreated:*"
    ]
    filter_prefix = "allied/mdss"
  }
}


resource "aws_lambda_permission" "airflow_allied_mdss" {
  count = local.is-development ? 0 : 1

  statement_id  = "InvokeLoadMDSSAirflowJob"
  action        = "lambda:InvokeFunction"
  function_name = module.airflow_trigger[0].lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3-raw-formatted-data-bucket.bucket.arn
}
