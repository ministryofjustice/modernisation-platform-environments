#####################################################################################
### Create the Lambda layer for Oracle Python ###
#####################################################################################

resource "aws_lambda_layer_version" "lambda_layer_oracle_python" {
  layer_name          = "cwa-extract-oracle-python"
  description         = "Oracle DB layer for Python"
  s3_bucket           = aws_s3_bucket.lambda_layer_dependencies.bucket
  s3_key              = "lambda-layer-dependencies-development/lambda_dependencies.zip"
  compatible_runtimes = ["python3.10"]
}


######################################
### Lambda SG
######################################

resource "aws_security_group" "cwa_extract" {
  name        = "${local.application_name_short}-${local.environment}-cwa-extract-lambda-security-group"
  description = "CWA Extract Lambda Security Group"
  vpc_id      = data.aws_vpc.shared.id

  egress {
    description = "outbound access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-cwa-extract-lambda-security-group" }
  )
}

######################################
### Lambda Resources
######################################

resource "aws_lambda_function" "cwa_extract" {

  description      = "Connect to CWA DB, extracts data into JSON files, uploads them to S3 and creates SNS message and SQS entries with S3 references"
  function_name    = "cwa_extract_function"
  role             = aws_iam_role.cwa_extract_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  filename         = "lambda/cwa_extract_lambda/cwa_lambda.zip"
  source_code_hash = filebase64sha256("lambda/cwa_extract_lambda/cwa_lambda.zip")
  timeout          = 10
  memory_size      = 128
  runtime          = "python3.10"
  layers           = [aws_lambda_layer_version.lambda_layer_oracle_python.arn]

  vpc_config {
    security_group_ids = [aws_security_group.cwa_extract.id]
    subnet_ids         = [data.aws_subnet.data_subnets_a.id]
  }
  

  environment {
    variables = {
      PROCEDURES_CONFIG = aws_secretsmanager_secret.cwa_procedures_config.name
      TARGET_BUCKET     = aws_s3_bucket.data.bucket
      SNS_TOPIC         = aws_sns_topic.priority_p1.arn
      DB_SECRET_NAME    = aws_secretsmanager_secret.cwa_db_secret.name
      AWS_REGION        = data.aws_region.current.name
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-cwa-extract" }
  )
}