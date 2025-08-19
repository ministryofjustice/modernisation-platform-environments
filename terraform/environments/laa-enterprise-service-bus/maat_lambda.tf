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
  source_security_group_id = local.application_data.accounts[local.environment].vpc_endpoint_sg
  security_group_id        = aws_security_group.maat_provider_load_sg.id
  description              = "Outbound 1521 Access to MAAT DB"
}

resource "aws_security_group_rule" "maat_provider_load_egress_https_sm" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = local.application_data.accounts[local.environment].maatdb_sg
  security_group_id        = aws_security_group.maat_provider_load_sg.id
  description              = "Outbound 443 to LAA VPC Endpoint SG"
}


# resource "aws_lambda_function" "maat_lambda" {
#   filename         = "maat_lambda.zip"
#   function_name    = "maat_lambda_function"
#   role             = aws_iam_role.maat_lambda_role.arn
#   handler          = "index.test"
#   runtime          = "python3.11"
#   source_code_hash = filebase64sha256("lambda.zip")

# #   vpc_config {
# #     subnet_ids         = # Replace with your private subnet(s)
# #     security_group_ids = # Replace with appropriate SG
# #   }

#   timeout = 10
#   memory_size = 128
# }