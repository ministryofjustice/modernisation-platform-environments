# Upload the Layer to S3

resource "aws_s3_object" "lambda_layer_s3" {
  bucket = aws_s3_bucket.lambda_payment_load.bucket
  key    = "lambda/layer.zip"
  source = "lambda/layer.zip"
}

resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name               = "${local.application_name}-${local.environment}-payment-load-layer"
  s3_bucket                = aws_s3_bucket.lambda_payment_load.bucket
  s3_key                   = aws_s3_object.lambda_layer_s3.key
  compatible_runtimes      = ["python3.10"]
  compatible_architectures = ["x86_64"]
  description              = "Lambda Layer for ${local.application_name} Payment Load"

  depends_on = [aws_s3_object.lambda_layer_s3]
}

# Lambda Function
resource "aws_lambda_function" "lambda_function" {
  function_name = "${local.application_name}-${local.environment}-payment-load"
  filename      = "lambda/function.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  role          = aws_iam_role.lambda_execution_role.arn
  layers        = [aws_lambda_layer_version.lambda_layer.arn]
  architectures = ["x86_64"]
  memory_size   = 128
  timeout       = 120

  environment {
    variables = {
      IS_PRODUCTION   = local.is-production ? "true" : "false"
      LD_LIBRARY_PATH = "/opt/instantclient_12_2_linux"
      S3_BUCKET_NAME  = aws_s3_bucket.lambda_payment_load.bucket
      SECRET_NAME     = aws_secretsmanager_secret.secret_lambda_s3.name
    }
  }

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-payment-load"
  })

  depends_on = [aws_lambda_layer_version.lambda_layer]
}
