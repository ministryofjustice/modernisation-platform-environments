######################################
### Lambda SG
######################################

resource "aws_security_group" "patch_ccms_provider_load" {
  count       = local.environment == "test" ? 1 : 0
  name        = "${local.application_name_short}-${local.environment}-patch-ccms-provider-load-lambda-security-group"
  description = "CCMS Provider Load Lambda Security Group"
  vpc_id      = data.aws_vpc.shared.id

  revoke_rules_on_delete = true

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-patch-ccms-provider-load-lambda-security-group" }
  )
}

resource "aws_security_group_rule" "patch_ccms_provider_load_egress_oracle" {
  count             = local.environment == "test" ? 1 : 0
  type              = "egress"
  from_port         = 1521
  to_port           = 1521
  protocol          = "tcp"
  cidr_blocks       = ["10.26.100.243/32"] # Patch CCMS Database IP
  security_group_id = aws_security_group.patch_ccms_provider_load[0].id
  description       = "Outbound 1521/1522 Access to CCMS DB"
}

resource "aws_security_group_rule" "patch_ccms_provider_load_egress_https" {
  count                    = local.environment == "test" ? 1 : 0
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = local.application_data.accounts[local.environment].vpc_endpoint_sg
  security_group_id        = aws_security_group.patch_ccms_provider_load[0].id
  description              = "Outbound 443 to LAA VPC Endpoint SG"
}

######################################
### Lambda Resources
######################################

resource "aws_lambda_function" "patch_ccms_provider_load" {
  count            = local.environment == "test" ? 1 : 0
  description      = "Connect to CCMS DB"
  function_name    = "patch_ccms_provider_load_function"
  role             = aws_iam_role.patch_ccms_provider_load_role[0].arn
  handler          = "lambda_function.lambda_handler"
  filename         = "lambda/provider_load_lambda/provider_load_package.zip"
  source_code_hash = filebase64sha256("lambda/provider_load_lambda/provider_load_package.zip")
  timeout          = 100
  memory_size      = 128
  runtime          = "python3.10"

  layers = [
    aws_lambda_layer_version.lambda_layer_oracle_python.arn
  ]

  vpc_config {
    security_group_ids = [aws_security_group.patch_ccms_provider_load[0].id]
    subnet_ids         = [data.aws_subnet.data_subnets_a.id]
  }


  environment {
    variables = {
      DB_SECRET_NAME         = aws_secretsmanager_secret.patch_ccms_db_mp_credentials[0].name
      PROCEDURE_SECRET_NAME  = aws_secretsmanager_secret.patch_ccms_procedures_config[0].name
      LD_LIBRARY_PATH        = "/opt/instantclient_12_1"
      ORACLE_HOME            = "/opt/instantclient_12_1"
      SERVICE_NAME           = "patch-ccms-load-service"
      NAMESPACE              = "HUB20-CCMS-NS"
      ENVIRONMENT            = local.environment
      LOG_LEVEL              = "DEBUG"
      PURGE_LAMBDA_TIMESTAMP = aws_ssm_parameter.ccms_provider_load_timestamp.name
      TNS_ADMIN              = "/tmp/wallet_dir"
      BUCKET                 = aws_s3_bucket.wallet_files.bucket
      WALLET_OBJ             = "CCMS/wallet_dir.zip"
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-patch-ccms-provider-load" }
  )
}
