module "iam_assumable_role_admin" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.0"
  
  create_role = true

  role_name_prefix = "openmetadata"

  provider_url  = local.environment_configuration.apps_tools_eks_oidc_url

  role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSQuicksightAthenaAccess",
    module.openmetadata_iam_policy.iam_role_arn
  ]

  oidc_fully_qualified_subjects = ["system:serviceaccount:openmetadata:airflow"]

  tags = local.tags
}