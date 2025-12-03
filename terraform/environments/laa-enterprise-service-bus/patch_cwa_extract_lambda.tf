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
  from_port         = 2484
  to_port           = 2484
  protocol          = "tcp"
  cidr_blocks       = ["10.205.11.0/26", "10.205.11.64/26"] # CWA ECP Safe03 Subnet IP
  security_group_id = aws_security_group.patch_cwa_extract_sg[0].id
  description       = "Outbound 2484 Access to CWA DB Safe3 in ECP"
}

resource "aws_security_group_rule" "patch_cwa_extract_egress_blue_green" {
  count             = local.environment == "test" ? 1 : 0
  type              = "egress"
  from_port         = 2484
  to_port           = 2484
  protocol          = "tcp"
  cidr_blocks       = ["10.205.10.0/26", "10.205.10.64/26"] # CWA ECP Blue Green Subnet IP
  security_group_id = aws_security_group.patch_cwa_extract_sg[0].id
  description       = "CWA Prod - Blue Green LB"
}

resource "aws_security_group_rule" "patch_cwa_extract_egress_safe02" {
  count             = local.environment == "test" ? 1 : 0
  type              = "egress"
  from_port         = 2484
  to_port           = 2484
  protocol          = "tcp"
  cidr_blocks       = ["10.205.15.64/26", "10.205.15.0/26"] # CWA ECP SAFE02 Loadbalancer subnets
  security_group_id = aws_security_group.patch_cwa_extract_sg[0].id
  description       = "CWA Prod - Safe02 DB"
}

resource "aws_security_group_rule" "patch_cwa_extract_egress_safe01" {
  count             = local.environment == "test" ? 1 : 0
  type              = "egress"
  from_port         = 2484
  to_port           = 2484
  protocol          = "tcp"
  cidr_blocks       = ["10.205.14.0/26", "10.205.14.0/26"] # CWA ECP SAFE01 Loadbalancer subnets
  security_group_id = aws_security_group.patch_cwa_extract_sg[0].id
  description       = "CWA Prod - Safe01 DB"
}

resource "aws_security_group_rule" "patch_cwa_extract_egress_https_endpoint" {
  count                    = local.environment == "test" ? 1 : 0
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = local.application_data.accounts[local.environment].vpc_endpoint_sg
  security_group_id        = aws_security_group.patch_cwa_extract_sg[0].id
  description              = "Outbound 443 to LAA VPC Endpoint SG"
}

resource "aws_security_group_rule" "patch_cwa_extract_egress_https_s3" {
  count             = local.environment == "test" ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [local.application_data.accounts[local.environment].s3_vpc_endpoint_prefix]
  security_group_id = aws_security_group.patch_cwa_extract_sg[0].id
  description       = "Outbound 443 to LAA VPC Endpoint SG"
}

# Lambda Functions for CWA Extract Step Function
resource "aws_lambda_function" "patch_cwa_extract_lambda" {
  count             = local.environment == "test" ? 1 : 0
  description       = "Connect to CWA DB and invoke cwa extract procedure."
  function_name     = "patch_cwa_extract_lambda"
  role              = aws_iam_role.patch_cwa_extract_lambda_role[0].arn
  handler           = "lambda_function.lambda_handler"
  s3_bucket         = data.aws_s3_object.cwa_extract_zip.bucket
  s3_key            = data.aws_s3_object.cwa_extract_zip.key
  s3_object_version = data.aws_s3_object.cwa_extract_zip.version_id
  timeout           = 900
  memory_size       = 128
  runtime           = "python3.10"

  layers = [
    aws_lambda_layer_version.lambda_layer_oracle_python.arn,
  ]

  vpc_config {
    security_group_ids = [aws_security_group.patch_cwa_extract_sg[0].id]
    subnet_ids         = [data.aws_subnet.data_subnets_a.id]
  }

  environment {
    variables = {
      PROCEDURES_CONFIG = aws_secretsmanager_secret.cwa_procedures_config.name
      DB_SECRET_NAME    = aws_secretsmanager_secret.patch_cwa_db_secret[0].name
      LD_LIBRARY_PATH   = "/opt/instantclient_12_1"
      ORACLE_HOME       = "/opt/instantclient_12_1"
      SERVICE_NAME      = "cwa-extract-service"
      NAMESPACE         = "HUB20-CWA-NS"
      ENVIRONMENT       = "patch"
      LOG_LEVEL         = "DEBUG"
      TNS_ADMIN         = "/tmp/wallet_dir"
      WALLET_BUCKET     = data.aws_s3_bucket.lambda_files.bucket
      WALLET_OBJ        = "wallet_files/CWA/wallet_dir.zip"
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-patch-cwa-extract-lambda" }
  )
}

resource "aws_lambda_function" "patch_cwa_file_transfer_lambda" {
  count             = local.environment == "test" ? 1 : 0
  description       = "Connect to CWA DB, retrieve multiple json files of each extract and merge into single JSON file, uploads them to S3"
  function_name     = "patch_cwa_file_transfer_lambda"
  role              = aws_iam_role.patch_cwa_extract_lambda_role[0].arn
  handler           = "lambda_function.lambda_handler"
  s3_bucket         = data.aws_s3_object.cwa_file_transfer_zip.bucket
  s3_key            = data.aws_s3_object.cwa_file_transfer_zip.key
  s3_object_version = data.aws_s3_object.cwa_file_transfer_zip.version_id
  timeout           = 900
  memory_size       = 128
  runtime           = "python3.10"

  layers = [
    aws_lambda_layer_version.lambda_layer_oracle_python.arn
  ]

  vpc_config {
    security_group_ids = [aws_security_group.patch_cwa_extract_sg[0].id]
    subnet_ids         = [data.aws_subnet.data_subnets_a.id]
  }

  environment {
    variables = {
      TABLE_NAME_SECRET = aws_secretsmanager_secret.cwa_table_name_secret.name
      TARGET_BUCKET     = aws_s3_bucket.patch_data[0].bucket
      DB_SECRET_NAME    = aws_secretsmanager_secret.patch_cwa_db_secret[0].name
      LD_LIBRARY_PATH   = "/opt/instantclient_12_1"
      ORACLE_HOME       = "/opt/instantclient_12_1"
      SERVICE_NAME      = "cwa-file-transfer-service"
      NAMESPACE         = "HUB20-CWA-NS"
      ENVIRONMENT       = "patch"
      LOG_LEVEL         = "DEBUG"
      TNS_ADMIN         = "/tmp/wallet_dir"
      WALLET_BUCKET     = data.aws_s3_bucket.lambda_files.bucket
      WALLET_OBJ        = "wallet_files/CWA/wallet_dir.zip"
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-patch-cwa-extract-file-transfer-lambda" }
  )
}

resource "aws_lambda_function" "patch_cwa_sns_lambda" {
  count             = local.environment == "test" ? 1 : 0
  description       = "Send SNS message with timestamp for downstream provider load services to extract files"
  function_name     = "patch_cwa_sns_lambda"
  role              = aws_iam_role.patch_cwa_extract_lambda_role[0].arn
  handler           = "lambda_function.lambda_handler"
  s3_bucket         = data.aws_s3_object.cwa_sns_zip.bucket
  s3_key            = data.aws_s3_object.cwa_sns_zip.key
  s3_object_version = data.aws_s3_object.cwa_sns_zip.version_id
  timeout           = 300
  memory_size       = 128
  runtime           = "python3.10"

  layers = [
    "arn:aws:lambda:eu-west-2:017000801446:layer:AWSLambdaPowertoolsPython:2"
  ]

  vpc_config {
    security_group_ids = [aws_security_group.patch_cwa_extract_sg[0].id]
    subnet_ids         = [data.aws_subnet.data_subnets_a.id]
  }

  environment {
    variables = {
      PROVIDER_TOPIC       = aws_sns_topic.patch_priority_p1[0].arn
      PROVIDER_BANKS_TOPIC = aws_sns_topic.patch_provider_banks[0].arn
      SERVICE_NAME         = "cwa-sns-service"
      NAMESPACE            = "HUB20-CWA-NS"
      ENVIRONMENT          = "patch"
      LOG_LEVEL            = "DEBUG"
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-patch-cwa-sns-lambda" }
  )
}
