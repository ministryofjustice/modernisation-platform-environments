locals {
  datahub_environments_share = [
    "electronic-monitoring-data-${local.environment}"
  ]
}

module "mwaa_execution_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.0"

  name            = "mwaa-execution"
  use_name_prefix = false
  trust_policy_permissions = {
    MwaaExecutionRole = {
      actions = ["sts:AssumeRole", "sts:TagSession"]
      principals = [
        {
          type        = "Service"
          identifiers = ["airflow.amazonaws.com", "airflow-env.amazonaws.com"]
        }
      ]
    }
  }

  policies = {
    mwaa_execution_policy = module.mwaa_execution_iam_policy.arn
  }

  tags = local.tags
}

module "gha_mojas_airflow_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.0"

  name            = "github-actions-mojas-airflow"
  use_name_prefix = false

  policies = {
    GHAMoJASAirflow = module.gha_mojas_airflow_iam_policy.arn
  }
  enable_github_oidc     = true
  oidc_wildcard_subjects = ["moj-analytical-services/airflow:*"]

  tags = local.tags
}

module "gha_moj_ap_airflow_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.0"

  name            = "github-actions-ministryofjustice-analytical-platform-airflow"
  use_name_prefix = false
  policies = {
    gha-moj-ap-airflow = module.gha_moj_ap_airflow_iam_policy.arn
  }
  enable_github_oidc     = true
  oidc_wildcard_subjects = ["ministryofjustice/analytical-platform-airflow:*"]

  tags = local.tags
}

# module "create_airflow_token_iam_role" {
#checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
#checkov:skip=CKV_TF_2:Module registry does not support tags for versions

# source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
# version = "5.59.0"

# trusted_role_arns = [
#   "arn:aws:iam::${local.datahub_environments_share[0]}:airflow_trigger_lambda_role",
# ]

# create_role = true
# role_name   = "data-factory-create-airflow-token"

# custom_role_policy_arns = [
#   module.create_airflow_token_iam_policy.arn
# ]

# tags = local.tags
#}
