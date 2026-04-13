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

  trust_policy_conditions = [
    {
      # https://github.com/ministryofjustice/analytical-platform-airflow-github-actions/blob/main/.github/workflows/shared-release-container.yml
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:job_workflow_ref"
      values   = ["ministryofjustice/analytical-platform-airflow-github-actions/.github/workflows/shared-release-container.yml@*"]
    },
    {
      # https://github.com/ministryofjustice/analytical-platform-airflow/blob/main/.github/workflows/workflow-validation.yml
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:workflow_ref"
      values   = ["ministryofjustice/analytical-platform-airflow/.github/workflows/workflow-validation.yml@*"]
    }
  ]

  policies = {
    ecr_access = module.ecr_access_iam_policy.arn
  }

  tags = local.tags
}

module "snyk_analytical_platform_airflow_container_scanning_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  enable_github_oidc = true
  use_name_prefix    = false

  name = "snyk-analytical-platform-airflow-container-scanning"

  oidc_wildcard_subjects = [
    "ministryofjustice/*",
    "moj-analytical-services/*"
  ]

  trust_policy_conditions = [
    {
      # https://github.com/ministryofjustice/analytical-platform-airflow-github-actions/blob/main/.github/workflows/shared-scan-container.yml
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:job_workflow_ref"
      values   = ["ministryofjustice/analytical-platform-airflow-github-actions/.github/workflows/shared-scan-container.yml@*"]
    },
    {
      # https://github.com/ministryofjustice/analytical-platform-airflow/blob/main/.github/workflows/workflow-validation.yml
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:workflow_ref"
      values   = ["ministryofjustice/analytical-platform-airflow/.github/workflows/workflow-validation.yml@*"]
    }
  ]

  policies = {
    snyk_analytical_platform_airflow_container_scanning = module.snyk_analytical_platform_airflow_container_scanning_iam_policy.arn
  }

  tags = local.tags
}

module "trivy_analytical_platform_airflow_container_scanning_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  enable_github_oidc = true
  use_name_prefix    = false

  name = "trivy-analytical-platform-airflow-container-scanning"

  oidc_wildcard_subjects = [
    "ministryofjustice/*",
    "moj-analytical-services/*"
  ]

  trust_policy_conditions = [
    {
      # https://github.com/ministryofjustice/analytical-platform-airflow-github-actions/blob/main/.github/workflows/shared-scan-container.yml
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:job_workflow_ref"
      values   = ["ministryofjustice/analytical-platform-airflow-github-actions/.github/workflows/shared-scan-container.yml@*"]
    },
    {
      # https://github.com/ministryofjustice/analytical-platform-airflow/blob/main/.github/workflows/workflow-validation.yml
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:workflow_ref"
      values   = ["ministryofjustice/analytical-platform-airflow/.github/workflows/workflow-validation.yml@*"]
    }
  ]

  policies = {
    trivy_analytical_platform_airflow_container_scanning = module.trivy_analytical_platform_airflow_container_scanning_iam_policy.arn
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

  create          = true
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
    platformEngineerAdminAssume = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${one(data.aws_iam_roles.platform_engineer_admin_sso_role.names)}"]
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

  create          = true
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
    platformEngineerAdminAssume = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]

      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      }]

      condition = [{
        test     = "ArnLike"
        variable = "aws:PrincipalArn"
        values = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/AWSReservedSSO_platform-engineer-admin_*"
        ]
      }]
    }
  }

  policies = {
    data-engineering-datalake-access-terraform = module.data_engineering_datalake_access_terraform_iam_policy.arn
  }

  tags = local.tags
}
