######################################
### Lambda SG
######################################

resource "aws_security_group" "ccms_provider_load" {
  name        = "${local.application_name_short}-${local.environment}-ccms-provider-load-lambda-security-group"
  description = "CCMS Provider Load Lambda Security Group"
  vpc_id      = data.aws_vpc.shared.id

  revoke_rules_on_delete = true

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-ccms-provider-load-lambda-security-group" }
  )
}

resource "aws_security_group_rule" "ccms_provider_load_egress_oracle" {
  type              = "egress"
  from_port         = local.environment == "test" ? 1522 : 1521
  to_port           = local.environment == "test" ? 1522 : 1521
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].ccms_database_ip]
  security_group_id = aws_security_group.ccms_provider_load.id
  description       = "Outbound 1521/1522 Access to CCMS DB"
}

resource "aws_security_group_rule" "ccms_provider_load_egress_https" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = local.application_data.accounts[local.environment].vpc_endpoint_sg
  security_group_id        = aws_security_group.ccms_provider_load.id
  description              = "Outbound 443 to LAA VPC Endpoint SG"
}

######################################
### Lambda Resources
######################################

resource "aws_lambda_function" "ccms_provider_load" {

  description      = "Connect to CCMS DB"
  function_name    = "ccms_provider_load_function"
  role             = aws_iam_role.ccms_provider_load_role.arn
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
    security_group_ids = [aws_security_group.ccms_provider_load.id]
    subnet_ids         = [data.aws_subnet.data_subnets_a.id]
  }


  environment {
    variables = {
      DB_SECRET_NAME         = aws_secretsmanager_secret.ccms_db_mp_credentials.name
      PROCEDURE_SECRET_NAME  = aws_secretsmanager_secret.ccms_procedures_config.name
      LD_LIBRARY_PATH        = "/opt/instantclient_12_1"
      ORACLE_HOME            = "/opt/instantclient_12_1"
      SERVICE_NAME           = "ccms-load-service"
      NAMESPACE              = "HUB20-CCMS-NS"
      ENVIRONMENT            = local.environment
      LOG_LEVEL              = "DEBUG"
      PURGE_LAMBDA_TIMESTAMP = aws_ssm_parameter.ccms_provider_load_timestamp.name
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-ccms-provider-load" }
  )
}
