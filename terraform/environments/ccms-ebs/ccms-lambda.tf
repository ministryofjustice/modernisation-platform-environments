# Upload the Layer to S3

resource "aws_s3_object" "lambda_layer_s3" {
  bucket = aws_s3_bucket.lambda_payment_load.bucket
  key    = "lambda/layerV2.zip"
  source = "lambda/layerV2.zip"
}

# Lambda Layer
resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name               = "${local.application_name}-${local.environment}-payment-load-layer"
  s3_bucket                = aws_s3_bucket.lambda_payment_load.bucket
  s3_key                   = aws_s3_object.lambda_layer_s3.key
  compatible_runtimes      = ["python3.10"]
  compatible_architectures = ["x86_64"]
  description              = "Lambda Layer for ${local.application_name} Payment Load"

  depends_on = [aws_s3_object.lambda_layer_s3]
}

# SG for Lambda
resource "aws_security_group" "lambda_security_group" {
  name        = "${local.application_name}-${local.environment}-lambda-sg"
  description = "SG traffic control for Payment Load Lambda"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    from_port   = 1521
    to_port     = 1522
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags,
    { Name = "${local.application_name}-${local.environment}-lambda-sg" }
  )
}


# Lambda Function
resource "aws_lambda_function" "lambda_function" {
  function_name = "${local.application_name}-${local.environment}-payment-load"
  filename      = "lambda/functionV2.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  role          = aws_iam_role.lambda_execution_role.arn
  layers        = [aws_lambda_layer_version.lambda_layer.arn]
  architectures = ["x86_64"]
  memory_size   = 128
  timeout       = 120

  vpc_config {
    subnet_ids         = [data.aws_subnet.data_subnets_a.id]
    security_group_ids = [aws_security_group.lambda_security_group.id]
  }
  environment {
    variables = {
      IS_PRODUCTION   = local.is-production ? "true" : "false"
      LD_LIBRARY_PATH = "/opt/instantclient_12_2_linux"
      S3_BUCKET_NAME  = aws_s3_bucket.lambda_payment_load.bucket
      SECRET_NAME     = aws_secretsmanager_secret.secret_lambda_s3.name
    }
  }
  logging_config {
    log_format            = "JSON"
    application_log_level = "INFO"
    system_log_level      = "INFO"
  }

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-payment-load"
  })

  depends_on = [aws_lambda_layer_version.lambda_layer]
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.lambda_payment_load.arn
}

# resource "aws_s3_bucket_notification" "lambda_trigger" {
#   bucket = aws_s3_bucket.lambda_payment_load.id

#   lambda_function {
#     lambda_function_arn = aws_lambda_function.lambda_function.arn
#     events              = ["s3:ObjectCreated:*"]
#     filter_suffix       = ".xlsx"
#   }

#   depends_on = [aws_lambda_permission.allow_bucket]
# }