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
  from_port         = local.environment == "production" ? 2484 : 1571
  to_port           = local.environment == "production" ? 2484 : 1571
  protocol          = "tcp"
  cidr_blocks       = local.application_data.accounts[local.environment].cwa_database_ip
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
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [local.application_data.accounts[local.environment].s3_vpc_endpoint_prefix]
  security_group_id = aws_security_group.cwa_extract_new.id
  description       = "Outbound 443 to LAA VPC Endpoint SG"
}

######################################
### Lambda Resources For Step Function
######################################
resource "aws_lambda_function" "cwa_extract_lambda" {

  description      = "Connect to CWA DB and invoke cwa extract procedure."
  function_name    = "cwa_extract_lambda"
  role             = aws_iam_role.cwa_extract_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  s3_bucket        = data.aws_s3_object.cwa_extract_zip.bucket
  s3_key           = data.aws_s3_object.cwa_extract_zip.key
  s3_object_version = data.aws_s3_object.cwa_extract_zip.version_id
  timeout          = 900
  memory_size      = 128
  runtime          = "python3.10"

  layers = [
    aws_lambda_layer_version.lambda_layer_oracle_python.arn
  ]

  vpc_config {
    security_group_ids = [aws_security_group.cwa_extract_new.id]
    subnet_ids         = [data.aws_subnet.data_subnets_a.id]
  }

  environment {
    variables = {
      PROCEDURES_CONFIG = aws_secretsmanager_secret.cwa_procedures_config.name
      DB_SECRET_NAME    = aws_secretsmanager_secret.cwa_db_secret.name
      LD_LIBRARY_PATH   = "/opt/instantclient_12_1"
      ORACLE_HOME       = "/opt/instantclient_12_1"
      SERVICE_NAME      = "cwa-extract-service"
      NAMESPACE         = "HUB20-CWA-NS"
      ENVIRONMENT       = local.environment
      LOG_LEVEL         = "DEBUG"
      TNS_ADMIN         = "tmp/wallet_dir"
      WALLET_BUCKET     = data.aws_s3_bucket.lambda_files.bucket
      WALLET_OBJ        = "wallet_files/CWA/wallet_dir.zip"
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-cwa-extract-lambda" }
  )
}

resource "aws_lambda_function" "cwa_file_transfer_lambda" {

  description      = "Connect to CWA DB, retrieve multiple json files of each extract and merge into single JSON file, uploads them to S3"
  function_name    = "cwa_file_transfer_lambda"
  role             = aws_iam_role.cwa_extract_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  s3_bucket        = data.aws_s3_object.cwa_file_transfer_zip.bucket
  s3_key           = data.aws_s3_object.cwa_file_transfer_zip.key
  s3_object_version = data.aws_s3_object.cwa_file_transfer_zip.version_id
  timeout          = 900
  memory_size      = 128
  runtime          = "python3.10"

  layers = [
    aws_lambda_layer_version.lambda_layer_oracle_python.arn
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
      LD_LIBRARY_PATH   = "/opt/instantclient_12_1"
      ORACLE_HOME       = "/opt/instantclient_12_1"
      SERVICE_NAME      = "cwa-file-transfer-service"
      NAMESPACE         = "HUB20-CWA-NS"
      ENVIRONMENT       = local.environment
      LOG_LEVEL         = "DEBUG"
      TNS_ADMIN         = "tmp/wallet_dir"
      WALLET_BUCKET     = data.aws_s3_bucket.lambda_files.bucket
      WALLET_OBJ        = "wallet_files/CWA/wallet_dir.zip"
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-cwa-extract-file-transfer-lambda" }
  )
}

resource "aws_lambda_function" "cwa_sns_lambda" {

  description      = "Send SNS message with timestamp for downstream provider load services to extract files"
  function_name    = "cwa_sns_lambda"
  role             = aws_iam_role.cwa_extract_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  s3_bucket        = data.aws_s3_object.cwa_sns_zip.bucket
  s3_key           = data.aws_s3_object.cwa_sns_zip.key
  s3_object_version = data.aws_s3_object.cwa_sns_zip.version_id
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
    { Name = "${local.application_name_short}-${local.environment}-cwa--sns-lambda" }
  )
}
