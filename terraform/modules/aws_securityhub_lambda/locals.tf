locals {
  securityhub_accounts = jsondecode(
    data.aws_ssm_parameter.aws_accounts.value
  ).accounts
}
