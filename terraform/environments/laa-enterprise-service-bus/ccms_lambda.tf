#####################################################################################
### Create the Lambda layer for Oracle Python ###
#####################################################################################

# resource "aws_lambda_layer_version" "lambda_layer_oracle_python" {
#   layer_name          = "cwa-extract-oracle-python"
#   description         = "Oracle DB layer for Python"
#   s3_bucket           = aws_s3_object.lambda_layer_zip.bucket
#   s3_key              = aws_s3_object.lambda_layer_zip.key
#   s3_object_version   = aws_s3_object.lambda_layer_zip.version_id
#   source_code_hash    = filebase64sha256("layers/lambda_dependencies.zip")
#   compatible_runtimes = ["python3.10"]
# }

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
  from_port         = 1522
  to_port           = 1522
  protocol          = "tcp"
  cidr_blocks       = [local.application_data.accounts[local.environment].ccms_database_ip]
  security_group_id = aws_security_group.ccms_provider_load.id
  description       = "Outbound 1522 Access to CCMS DB"
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

# resource "aws_lambda_function" "ccms_provider_load" {

#   description      = "Connect to CCMS DB"
#   function_name    = "ccms_provider_load_function"
#   role             = aws_iam_role.ccms_provider_load_role.arn
#   handler          = "lambda_function.lambda_handler"
#   filename         = "lambda/ccms_provider_load_lambda/ccms_lambda.zip"
#   source_code_hash = filebase64sha256("lambda/ccms_provider_load_lambda/ccms_lambda.zip")
#   timeout          = 900
#   memory_size      = 128
#   runtime          = "python3.10"

#   layers = [
#     aws_lambda_layer_version.lambda_layer_oracle_python.arn,
#     "arn:aws:lambda:eu-west-2:017000801446:layer:AWSLambdaPowertoolsPython:2"
#   ]

#   vpc_config {
#     security_group_ids = [aws_security_group.ccms_provider_load.id]
#     subnet_ids         = [data.aws_subnet.data_subnets_a.id]
#   }
  

#   environment {
#     variables = {
#       DB_SECRET_NAME    = aws_secretsmanager_secret.ccms_db_mp_credentials.name
#     }
#   }

#   tags = merge(
#     local.tags,
#     { Name = "${local.application_name_short}-${local.environment}-ccms-provider-load" }
#   )
# }