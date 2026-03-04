module "mwaa_execution_iam_role" {

  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.59.0"

  create_role = true

  role_name         = "internal-mwaa-execution"
  role_requires_mfa = false

  trusted_role_services = [
    "airflow.amazonaws.com",
    "airflow-env.amazonaws.com"
  ]

  custom_role_policy_arns = [module.mwaa_execution_iam_policy.arn]

  tags = local.tags
}

module "gha_moj_ap_airflow_iam_role" {
  count = local.create_internal_airflow ? 1 : 0
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.59.0"

  name = "github-actions-ministryofjustice-analytical-platform-int-airflow"

  policies = {
    gha-moj-ap-airflow = module.gha_moj_ap_airflow_iam_policy[0].arn
  }

  subjects = ["ministryofjustice/analytical-platform--airflow:*"]

  tags = local.tags
}
