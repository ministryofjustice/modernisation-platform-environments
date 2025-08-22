######################################
### Lambda SG
######################################

resource "aws_security_group" "maat_provider_load_sg" {
  name        = "${local.application_name_short}-${local.environment}-maat-provider-load-lambda-security-group"
  description = "MAAT Provider Lambda Security Group"
  vpc_id      = data.aws_vpc.shared.id

  revoke_rules_on_delete = true

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-maat-provider-load-lambda-security-group" }
  )
}

resource "aws_security_group_rule" "maat_provider_load_egress_oracle" {
  type                     = "egress"
  from_port                = 1521
  to_port                  = 1521
  protocol                 = "tcp"
  source_security_group_id = local.application_data.accounts[local.environment].maatdb_sg
  security_group_id        = aws_security_group.maat_provider_load_sg.id
  description              = "Outbound 1521 Access to MAAT DB"
}

resource "aws_security_group_rule" "maat_provider_load_egress_https_sm" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = local.application_data.accounts[local.environment].vpc_endpoint_sg
  security_group_id        = aws_security_group.maat_provider_load_sg.id
  description              = "Outbound 443 to LAA VPC Endpoint SG"
}

######################################
### Lambda Resources
######################################

resource "aws_lambda_function" "maat_provider_load" {

  description      = "Connect to MAAT DB"
  function_name    = "maat_provider_load_function"
  role             = aws_iam_role.maat_provider_load_role.arn
  handler          = "lambda_function.lambda_handler"
  filename         = "lambda/provider_load_lambda/provider_load_package.zip"
  source_code_hash = filebase64sha256("lambda/provider_load_lambda/provider_load_package.zip")
  timeout          = 300
  memory_size      = 128
  runtime          = "python3.10"

  layers = [
    aws_lambda_layer_version.lambda_layer_oracle_python.arn,
    "arn:aws:lambda:eu-west-2:017000801446:layer:AWSLambdaPowertoolsPython:2"
  ]

  vpc_config {
    security_group_ids = [aws_security_group.maat_provider_load_sg.id]
    subnet_ids         = [data.aws_subnet.data_subnets_a.id]
  }


  environment {
    variables = {
      DB_SECRET_NAME        = aws_secretsmanager_secret.maat_db_mp_credentials.name
      PROCEDURE_SECRET_NAME = aws_secretsmanager_secret.maat_procedures_config.name
      LD_LIBRARY_PATH       = "/opt/instantclient_12_2_linux"
      ORACLE_HOME           = "/opt/instantclient_12_2_linux"
      SERVICE_NAME          = "maat-load-service"
      NAMESPACE             = "MAATProviderLoadService"
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-maat-provider-load" }
  )
}

resource "aws_lambda_event_source_mapping" "maat_provider_q_trigger" {
  event_source_arn = aws_sqs_queue.maat_provider_q.arn
  function_name    = aws_lambda_function.maat_provider_load.arn
  batch_size       = 1
}