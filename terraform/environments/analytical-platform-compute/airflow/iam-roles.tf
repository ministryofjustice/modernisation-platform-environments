module "mwaa_execution_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "6.1.2"

  create_role = true

  role_name         = "mwaa-execution"
  role_requires_mfa = false

  trusted_role_services = [
    "airflow.amazonaws.com",
    "airflow-env.amazonaws.com"
  ]

  custom_role_policy_arns = [module.mwaa_execution_iam_policy.arn]

  tags = local.tags
}

module "gha_mojas_airflow_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "6.1.2"

  name = "github-actions-mojas-airflow"

  policies = {
    GHAMoJASAirflow = module.gha_mojas_airflow_iam_policy.arn
  }

  subjects = ["moj-analytical-services/airflow:*"]

  tags = local.tags
}

module "gha_moj_ap_airflow_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "6.1.2"

  name = "github-actions-ministryofjustice-analytical-platform-airflow"

  policies = {
    gha-moj-ap-airflow = module.gha_moj_ap_airflow_iam_policy.arn
  }

  subjects = ["ministryofjustice/analytical-platform-airflow:*"]

  tags = local.tags
}
