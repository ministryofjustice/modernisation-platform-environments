######################################
### Lambda SG
######################################

resource "aws_security_group" "cwa_extract_new" {
  name        = "${local.application_name_short}-${local.environment}-cwa-extract-lambda-security-group-new"
  description = "CWA Extract Lambda Security Group New"
  vpc_id      = data.aws_vpc.shared.id

  revoke_rules_on_delete = true

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-cwa-extract-lambda-security-group-new" }
  )
}

resource "aws_security_group_rule" "cwa_extract_egress_oracle_new" {
  type              = "egress"
  from_port         = 1571
  to_port           = 1571
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].cwa_database_ip]
  security_group_id = aws_security_group.cwa_extract_new.id
  description       = "Outbound 1571 Access to CWA DB"
}

resource "aws_security_group_rule" "cwa_extract_egress_https_sm" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = local.application_data.accounts[local.environment].vpc_endpoint_sg
  security_group_id        = aws_security_group.cwa_extract_new.id
  description              = "Outbound 443 to LAA VPC Endpoint SG"
}

resource "aws_security_group_rule" "cwa_extract_egress_https_s3" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  prefix_list_ids          = [local.application_data.accounts[local.environment].s3_vpc_endpoint_prefix]
  security_group_id        = aws_security_group.cwa_extract_new.id
  description              = "Outbound 443 to LAA VPC Endpoint SG"
}

resource "aws_security_group_rule" "cwa_extract_egress_efs" {
  type                     = "egress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = local.application_data.accounts[local.environment].cwa_efs_sg
  security_group_id        = aws_security_group.cwa_extract_new.id
  description              = "Outbound NFS to CWA EFS SG"
}

######################################
### Lambda Resources
######################################

# resource "aws_lambda_function" "cwa_extract" {

#   description      = "Connect to CWA DB, extracts data into JSON files, uploads them to S3 and creates SNS message and SQS entries with S3 references"
#   function_name    = "cwa_extract_function"
#   role             = aws_iam_role.cwa_extract_lambda_role.arn
#   handler          = "lambda_function.lambda_handler"
#   filename         = "lambda/cwa_extract_lambda/cwa_lambda.zip"
#   source_code_hash = filebase64sha256("lambda/cwa_extract_lambda/cwa_lambda.zip")
#   timeout          = 300
#   memory_size      = 128
#   runtime          = "python3.10"

#   layers = [
#     aws_lambda_layer_version.lambda_layer_oracle_python.arn,
#     "arn:aws:lambda:eu-west-2:017000801446:layer:AWSLambdaPowertoolsPython:2"
#   ]

#   file_system_config {
#     arn              = "arn:aws:elasticfilesystem:eu-west-2:940482439836:access-point/fsap-0b3ad02899e9b5922"
#     local_mount_path = "/mnt/efs"
#   }

#   vpc_config {
#     security_group_ids = [aws_security_group.cwa_extract_new.id]
#     subnet_ids         = [data.aws_subnet.data_subnets_a.id]
#   }
  

#   environment {
#     variables = {
#       PROCEDURES_CONFIG = aws_secretsmanager_secret.cwa_procedures_config.name
#       TARGET_BUCKET     = aws_s3_bucket.data.bucket
#       SNS_TOPIC         = aws_sns_topic.priority_p1.arn
#       DB_SECRET_NAME    = aws_secretsmanager_secret.cwa_db_secret.name
#       LD_LIBRARY_PATH   = "/opt/instantclient_12_2_linux"
#       ORACLE_HOME       = "/opt/instantclient_12_2_linux"
#     }
#   }

#   tags = merge(
#     local.tags,
#     { Name = "${local.application_name_short}-${local.environment}-cwa-extract" }
#   )
# }

######################################
### Lambda Resources For Step Function
######################################
resource "aws_lambda_function" "cwa_extract_lambda" {

  description      = "Connect to CWA DB, extracts data into JSON files, uploads them to S3 and creates SNS message and SQS entries with S3 references"
  function_name    = "cwa_extract_lambda"
  role             = aws_iam_role.cwa_extract_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  filename         = "lambda/cwa_extract_lambda/cwa_extract_package.zip"
  source_code_hash = filebase64sha256("lambda/cwa_extract_lambda/cwa_extract_package.zip")
  timeout          = 300
  memory_size      = 128
  runtime          = "python3.10"

  layers = [
    aws_lambda_layer_version.lambda_layer_oracle_python.arn,
    "arn:aws:lambda:eu-west-2:017000801446:layer:AWSLambdaPowertoolsPython:2"
  ]

  vpc_config {
    security_group_ids = [aws_security_group.cwa_extract_new.id]
    subnet_ids         = [data.aws_subnet.data_subnets_a.id]
  }
  
  environment {
    variables = {
      PROCEDURES_CONFIG = aws_secretsmanager_secret.cwa_procedures_config.name
      TARGET_BUCKET     = aws_s3_bucket.data.bucket
      SNS_TOPIC         = aws_sns_topic.priority_p1.arn
      DB_SECRET_NAME    = aws_secretsmanager_secret.cwa_db_secret.name
      LD_LIBRARY_PATH   = "/opt/instantclient_12_2_linux"
      ORACLE_HOME       = "/opt/instantclient_12_2_linux"
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-cwa-extract-lambda" }
  )
}

resource "aws_lambda_function" "cwa_file_transfer_lambda" {

  description      = "Connect to CWA DB, extracts data into JSON files, uploads them to S3 and creates SNS message and SQS entries with S3 references"
  function_name    = "cwa_file_transfer_lambda"
  role             = aws_iam_role.cwa_extract_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  filename         = "lambda/cwa_file_transfer_lambda/cwa_file_transfer_package.zip"
  source_code_hash = filebase64sha256("lambda/cwa_file_transfer_lambda/cwa_file_transfer_package.zip")
  timeout          = 300
  memory_size      = 128
  runtime          = "python3.10"

  layers = [
    aws_lambda_layer_version.lambda_layer_oracle_python.arn,
    "arn:aws:lambda:eu-west-2:017000801446:layer:AWSLambdaPowertoolsPython:2"
  ]

  vpc_config {
    security_group_ids = [aws_security_group.cwa_extract_new.id]
    subnet_ids         = [data.aws_subnet.data_subnets_a.id]
  }

  environment {
    variables = {
      TABLE_NAME_SECRET = aws_secretsmanager_secret.cwa_table_name_secret.name
      TARGET_BUCKET     = aws_s3_bucket.data.bucket
      DB_SECRET_NAME    = aws_secretsmanager_secret.cwa_db_secret.name
      LD_LIBRARY_PATH   = "/opt/instantclient_12_2_linux"
      ORACLE_HOME       = "/opt/instantclient_12_2_linux"
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-cwa-extract-file-transfer-lambda" }
  )
}

resource "aws_lambda_function" "cwa_sns_lambda" {

  description      = "Connect to CWA DB, extracts data into JSON files, uploads them to S3 and creates SNS message and SQS entries with S3 references"
  function_name    = "cwa_sns_lambda"
  role             = aws_iam_role.cwa_extract_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  filename         = "lambda/cwa_sns_lambda/cwa_sns_lambda.zip"
  source_code_hash = filebase64sha256("lambda/cwa_sns_lambda/cwa_sns_lambda.zip")
  timeout          = 300
  memory_size      = 128
  runtime          = "python3.10"

  layers = [
    "arn:aws:lambda:eu-west-2:017000801446:layer:AWSLambdaPowertoolsPython:2"
  ]

  vpc_config {
    security_group_ids = [aws_security_group.cwa_extract_new.id]
    subnet_ids         = [data.aws_subnet.data_subnets_a.id]
  }

  environment {
    variables = {
      AWS_REGION = data.aws_region.current.region
      PROVIDER_TOPIC = aws_sns_topic.priority_p1.arn
      PROVIDER_BANKS_TOPIC = aws_sns_topic.provider_banks.arn
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-cwa--sns-lambda" }
  )
}
