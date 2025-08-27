######################################
### Lambda SG
######################################

resource "aws_security_group" "purge_lambda_sg" {
  name        = "${local.application_name_short}-${local.environment}-purge-lambda-security-group"
  description = "Purge Lambda Security Group"
  vpc_id      = data.aws_vpc.shared.id

  revoke_rules_on_delete = true

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-purge-lambda-security-group" }
  )
}

resource "aws_security_group_rule" "purge_lambda_egress_https_sm" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = local.application_data.accounts[local.environment].vpc_endpoint_sg
  security_group_id        = aws_security_group.purge_lambda_sg.id
  description              = "Outbound 443 to LAA VPC Endpoint SG"
}

resource "aws_security_group_rule" "purge_lambda_egress_https_s3" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [local.application_data.accounts[local.environment].s3_vpc_endpoint_prefix]
  security_group_id = aws_security_group.purge_lambda_sg.id
  description       = "Outbound 443 to LAA VPC Endpoint SG"
}

######################################
### Lambda Resources
######################################

resource "aws_lambda_function" "purge_lambda" {

  description      = "Deletes files from older than minimum timestamp value from ssm parameters"
  function_name    = "purge_lambda_function"
  role             = aws_iam_role.purge_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  filename         = "lambda/purge_lambda/purge_lambda_package.zip"
  source_code_hash = filebase64sha256("lambda/purge_lambda/purge_lambda_package.zip")
  timeout          = 100
  memory_size      = 128
  runtime          = "python3.10"

  vpc_config {
    security_group_ids = [aws_security_group.purge_lambda_sg.id]
    subnet_ids         = [data.aws_subnet.data_subnets_a.id]
  }


  environment {
    variables = {
      CCMS_TIMESTAMP     = aws_ssm_parameter.ccms_provider_load_timestamp.name
      CCLF_TIMESTAMP     = aws_ssm_parameter.cclf_provider_load_timestamp.name
      CCR_TIMESTAMP      = aws_ssm_parameter.ccr_provider_load_timestamp.name
      MAAT_TIMESTAMP     = aws_ssm_parameter.maat_provider_load_timestamp.name
      TARGET_BUCKET      = aws_s3_bucket.data.bucket
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-purge-lambda" }
  )
}
