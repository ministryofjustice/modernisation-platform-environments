module "openmetadata_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 6.1"

  create_role = true

  role_name         = "openmetadata"
  role_requires_mfa = false

  trusted_role_arns = ["arn:aws:iam::${local.environment_configuration.apps_tools_account_id}:root"]

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSQuicksightAthenaAccess",
    module.openmetadata_iam_policy.arn
  ]

  tags = local.tags
}
