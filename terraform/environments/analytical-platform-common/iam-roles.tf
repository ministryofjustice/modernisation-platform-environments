module "ecr_access_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  enable_github_oidc = true
  use_name_prefix    = false

  name = "ecr-access"

  oidc_wildcard_subjects = [
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

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  enable_github_oidc = true
  use_name_prefix    = false

  name = "analytical-platform-github-actions"

  oidc_wildcard_subjects = ["ministryofjustice/analytical-platform-airflow:*"]

  policies = {
    analytical_platform_github_actions = module.analytical_platform_github_actions_iam_policy.arn
  }

  tags = local.tags
}

module "analytical_platform_terraform_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  create = true
  use_name_prefix = false

  name = "analytical-platform-terraform"

  trust_policy_permissions = {
    githubActionsAssume = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      principals = [{
        type        = "AWS"
        identifiers = [module.analytical_platform_github_actions_iam_role.arn]
      }]
    }
  }

  policies = {
    analytical-platform-terraform = module.analytical_platform_terraform_iam_policy.arn
  }

  tags = local.tags
}

module "data_engineering_datalake_access_github_actions_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  enable_github_oidc = true
  use_name_prefix    = false

  name = "data-engineering-datalake-access-github-actions"

  oidc_wildcard_subjects = ["moj-analytical-services/data-engineering-datalake-access:*"]

  policies = {
    data_engineering_github_actions = module.data_engineering_datalake_access_github_actions_iam_policy.arn
  }

  tags = local.tags
}

module "data_engineering_datalake_access_terraform_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  create = true
  use_name_prefix = false

  name = "data-engineering-datalake-access-terraform"

  trust_policy_permissions = {
    dataEngineeringGithubActionsAssume = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      principals = [{
        type        = "AWS"
        identifiers = [module.data_engineering_datalake_access_github_actions_iam_role.arn]
      }]
    }
  }

  policies = {
    data-engineering-datalake-access-terraform = module.data_engineering_datalake_access_terraform_iam_policy.arn
  }

  tags = local.tags
}
