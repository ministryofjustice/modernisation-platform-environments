locals {
  account_id = data.aws_caller_identity.current.account_id

  pagerduty_state_bucket_name = "integration-hub-production-pagerduty-tfstate"
  pagerduty_state_key         = "pagerduty/terraform.tfstate"
  pagerduty_secret_name       = "pagerduty/api-key"
  pagerduty_role_name         = "integration-hub-pagerduty"

  pagerduty_state_allowed_principal_arns = [
    "arn:aws:iam::${local.account_id}:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_platform-engineer-admin_*",
    "arn:aws:iam::${local.account_id}:role/MemberInfrastructureAccess",
    "arn:aws:iam::${local.account_id}:role/github-actions-plan",
    "arn:aws:iam::${local.account_id}:role/github-actions-apply",
    "arn:aws:iam::${local.account_id}:role/github-actions/${local.pagerduty_role_name}"
  ]

  pagerduty_api_key_kms_principal_arns = [
    "arn:aws:iam::${local.account_id}:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_platform-engineer-admin_*",
    "arn:aws:iam::${local.account_id}:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_AdministratorAccess_*",
    "arn:aws:iam::${local.account_id}:role/MemberInfrastructureAccess",
    "arn:aws:iam::${local.account_id}:role/github-actions/${local.pagerduty_role_name}"
  ]
}
