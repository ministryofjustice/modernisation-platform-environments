data "aws_iam_policy_document" "powerbi_gateway_data_access" {
  statement {
    sid = "PowerBIAssumeDataRoles"

    actions = [
      "sts:AssumeRole",
    ]
    resources = formatlist("arn:aws:iam::%s:role/alpha_*", local.environment_configuration.powerbi_target_accounts)
  }

  statement {
    sid = "AccessPowerBIGatewayCredentials"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      aws_secretsmanager_secret.powerbi_gateway_reg_credentials.arn
    ]
  }
}


resource "aws_iam_policy" "powerbi_gateway_data_access" {
  name   = local.environment_configuration.powerbi_gateway_ec2.instance_name
  policy = data.aws_iam_policy_document.powerbi_gateway_data_access.json
}
