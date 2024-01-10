data "aws_iam_policy_document" "powerbi_gateway_data_access" {
  statement {
    sid = "PowerBIAssumeDataRoles"

    actions = [
      "sts:AssumeRole",
    ]
    resources = formatlist("arn:aws:iam::%s:role/alpha_*", local.environment_configuration.powerbi_target_accounts)
  }
}


resource "aws_iam_policy" "powerbi_gateway_data_access" {
  name   = local.environment_configuration.powerbi_gateway_ec2.instance_name
  policy = data.aws_iam_policy_document.powerbi_gateway_data_access.json
}
