module "quicksight_vpc_connection_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.59.0"

  create_role       = true
  role_name_prefix  = "quicksight-vpc-connection"
  role_requires_mfa = false

  trusted_role_services = ["quicksight.amazonaws.com"]

  custom_role_policy_arns = [module.quicksight_vpc_connection_iam_policy.arn]

  tags = local.tags
}

module "find_moj_data_quicksight_sa_assumable_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.59.0"

  allow_self_assume_role = false
  trusted_role_arns = [
    "arn:aws:iam::754256621582:role/cloud-platform-irsa-e5ba8827240d2ff3-live",
    "arn:aws:iam::754256621582:role/cloud-platform-irsa-1003dc6e42f4229f-live",
    "arn:aws:iam::754256621582:role/cloud-platform-irsa-25d122a26f9264de-live"
  ]

  create_role       = true
  role_requires_mfa = false
  role_name         = "find-moj-data-quicksight"

  custom_role_policy_arns = [module.find_moj_data_quicksight_policy.arn]

  tags = local.tags
}
