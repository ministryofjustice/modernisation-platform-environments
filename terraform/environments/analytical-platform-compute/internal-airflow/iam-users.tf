module "mwaa_ses_iam_user" {
  count = local.create_internal_airflow ? 1 : 0
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "5.59.0"

  name                          = "internal-mwaa-ses"
  create_iam_user_login_profile = false

  policy_arns = [module.mwaa_ses_policy[0].arn]

  tags = local.tags
}
