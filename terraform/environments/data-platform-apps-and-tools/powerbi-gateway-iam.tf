data "aws_iam_policy_document" "powerbi_gateway_data_access" {
  statement {
    sid = "local.environment_configuration.powerbi_gateway_ec2.instance_name"

    actions = [
      "sts:AssumeRole",
    ]
    resources = formatlist("arn:aws:iam::%s:root", local.environment_configuration.powerbi_target_accounts)
  }
}


resource "aws_iam_policy" "powerbi_gateway_data_access" {
  name   = local.environment_configuration.powerbi_gateway_ec2.instance_name
  path   = "/"
  policy = data.aws_iam_policy_document.powerbi_gateway_data_access.json
}
