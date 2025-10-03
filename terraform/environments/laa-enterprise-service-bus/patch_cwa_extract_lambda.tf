############################
### CWA Lambda Functions ###
############################
resource "aws_security_group" "patch_cwa_extract_sg" {
  count       = local.environment == "test" ? 1 : 0
  name        = "${local.application_name_short}-${local.environment}-patch-cwa-extract-lambda-security-group"
  description = "CWA Extract Lambda Security Group for CCMS Patch Testing"
  vpc_id      = data.aws_vpc.shared.id

  revoke_rules_on_delete = true

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-patch-cwa-extract-lambda-security-group" }
  )
}

resource "aws_security_group_rule" "patch_cwa_extract_egress_oracle" {
  count             = local.environment == "test" ? 1 : 0
  type              = "egress"
  from_port         = 1571
  to_port           = 1571
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].cwa_database_ip]
  security_group_id = aws_security_group.patch_cwa_extract_sg.id
  description       = "Outbound 1571 Access to CWA DB"
}

resource "aws_security_group_rule" "patch_cwa_extract_egress_https_endpoint" {
  count                    = local.environment == "test" ? 1 : 0
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = local.application_data.accounts[local.environment].vpc_endpoint_sg
  security_group_id        = aws_security_group.patch_cwa_extract_sg.id
  description              = "Outbound 443 to LAA VPC Endpoint SG"
}

resource "aws_security_group_rule" "patch_cwa_extract_egress_https_s3" {
  count             = local.environment == "test" ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [local.application_data.accounts[local.environment].s3_vpc_endpoint_prefix]
  security_group_id = aws_security_group.patch_cwa_extract_sg.id
  description       = "Outbound 443 to LAA VPC Endpoint SG"
}

resource "aws_lambda_function" "patch_cwa_extract_lambda" {
  count            = local.environment == "test" ? 1 : 0
  description      = "Connect to CWA DB and invoke cwa extract procedure."
  function_name    = "patch_cwa_extract_lambda"
  role             = aws_iam_role.patch_cwa_extract_lambda_role.arn
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
    security_group_ids = [aws_security_group.patch_cwa_extract_sg.id]
    subnet_ids         = [data.aws_subnet.data_subnets_a.id]
  }

  environment {
    variables = {
      PROCEDURES_CONFIG = aws_secretsmanager_secret.cwa_procedures_config.name
      DB_SECRET_NAME    = aws_secretsmanager_secret.patch_cwa_db_secret.name
      LD_LIBRARY_PATH   = "/opt/instantclient_12_2_linux"
      ORACLE_HOME       = "/opt/instantclient_12_2_linux"
      SERVICE_NAME      = "cwa-extract-service"
      NAMESPACE         = "HUB20-CWA-NS"
      ENVIRONMENT       = local.environment
      LOG_LEVEL         = "DEBUG"
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-patch-cwa-extract-lambda" }
  )
}

resource "aws_lambda_function" "patch_cwa_file_transfer_lambda" {
  count            = local.environment == "test" ? 1 : 0    
  description      = "Connect to CWA DB, retrieve multiple json files of each extract and merge into single JSON file, uploads them to S3"
  function_name    = "patch_cwa_file_transfer_lambda"
  role             = aws_iam_role.patch_cwa_extract_lambda_role.arn
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
    security_group_ids = [aws_security_group.patch_cwa_extract_sg.id]
    subnet_ids         = [data.aws_subnet.data_subnets_a.id]
  }

  environment {
    variables = {
      TABLE_NAME_SECRET = aws_secretsmanager_secret.cwa_table_name_secret.name
      TARGET_BUCKET     = aws_s3_bucket.data.bucket
      DB_SECRET_NAME    = aws_secretsmanager_secret.patch_cwa_db_secret.name
      LD_LIBRARY_PATH   = "/opt/instantclient_12_2_linux"
      ORACLE_HOME       = "/opt/instantclient_12_2_linux"
      SERVICE_NAME      = "cwa-file-transfer-service"
      NAMESPACE         = "HUB20-CWA-NS"
      ENVIRONMENT       = local.environment
      LOG_LEVEL         = "DEBUG"
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-patch-cwa-extract-file-transfer-lambda" }
  )
}

resource "aws_lambda_function" "patch_cwa_sns_lambda" {
  count            = local.environment == "test" ? 1 : 0
  description      = "Send SNS message with timestamp for downstream provider load services to extract files"
  function_name    = "patch_cwa_sns_lambda"
  role             = aws_iam_role.patch_cwa_extract_lambda_role.arn
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
    security_group_ids = [aws_security_group.patch_cwa_extract_sg.id]
    subnet_ids         = [data.aws_subnet.data_subnets_a.id]
  }

  environment {
    variables = {
      PROVIDER_TOPIC       = aws_sns_topic.priority_p1.arn
      PROVIDER_BANKS_TOPIC = aws_sns_topic.provider_banks.arn
      SERVICE_NAME         = "cwa-sns-service"
      NAMESPACE            = "HUB20-CWA-NS"
      ENVIRONMENT          = local.environment
      LOG_LEVEL            = "DEBUG"
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-patch-cwa-sns-lambda" }
  )
}