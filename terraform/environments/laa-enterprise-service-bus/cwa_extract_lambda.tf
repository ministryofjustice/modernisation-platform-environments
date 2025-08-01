#####################################################################################
### Create the Lambda layer for Oracle Python ###
#####################################################################################

resource "aws_lambda_layer_version" "lambda_layer_oracle_python" {
  layer_name          = "cwa-extract-oracle-python"
  description         = "Oracle DB layer for Python"
  s3_bucket           = aws_s3_bucket.lambda_layer_dependencies.bucket
  s3_key              = "cwa_extract_lambda/lambda_dependencies.zip"
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
    description = "Outbound SSH Access to CWA DB"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].cwa_database_ip]
  }
  egress {
    description = "Outbound 1521 Access to CWA DB"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].cwa_database_ip]
  }
  egress {
    description = "Outbound 443 to LAA VPC Endpoint SG"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [local.application_data.accounts[local.environment].vpc_endpoint_sg]
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
  timeout          = 900
  memory_size      = 128
  runtime          = "python3.10"

  layers = [
    aws_lambda_layer_version.lambda_layer_oracle_python.arn,
    "arn:aws:lambda:eu-west-2:017000801446:layer:AWSLambdaPowertoolsPython:2"
  ]

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
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-cwa-extract" }
  )
}