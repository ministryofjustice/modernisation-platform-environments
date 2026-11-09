locals {
  securityhub_accounts = jsondecode(
    data.aws_ssm_parameter.securityhub_accounts.value
  ).accounts
}
