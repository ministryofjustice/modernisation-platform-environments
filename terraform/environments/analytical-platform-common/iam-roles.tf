module "ecr_access_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "6.2.3"

  name = "ecr-access"

  subjects = [
    "ministryofjustice/*",
    "moj-analytical-services/*"
  ]

  policies = {
    ecr_access = module.ecr_access_iam_policy.arn
  }

  tags = local.tags
}

module "analytical_platform_github_actions_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "6.2.3"

  name = "analytical-platform-github-actions"

  subjects = ["ministryofjustice/analytical-platform-airflow:*"]

  policies = {
    analytical_platform_github_actions = module.analytical_platform_github_actions_iam_policy.arn
  }

  tags = local.tags
}

module "analytical_platform_terraform_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "6.2.3"

  create_role = true

  role_name         = "analytical-platform-terraform"
  role_requires_mfa = false

  trusted_role_arns = [module.analytical_platform_github_actions_iam_role.arn]

  custom_role_policy_arns = [module.analytical_platform_terraform_iam_policy.arn]

  tags = local.tags
}

module "data_engineering_datalake_access_github_actions_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "6.2.3"

  name = "data-engineering-datalake-access-github-actions"

  subjects = ["moj-analytical-services/data-engineering-datalake-access:*"]

  policies = {
    data_engineering_github_actions = module.data_engineering_datalake_access_github_actions_iam_policy.arn
  }

  tags = local.tags
}

module "data_engineering_datalake_access_terraform_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "6.2.3"

  create_role = true

  role_name         = "data-engineering-datalake-access-terraform"
  role_requires_mfa = false

  trusted_role_arns = [module.data_engineering_datalake_access_github_actions_iam_role.arn]

  custom_role_policy_arns = [module.data_engineering_datalake_access_terraform_iam_policy.arn]

  tags = local.tags
}
