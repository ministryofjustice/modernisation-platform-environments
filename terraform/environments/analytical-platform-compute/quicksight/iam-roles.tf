# Upgrading the IAM module from v5.x to v6.x introduces breaking changes that cause IAM roles and policies to be replaced. Therefore, we are not proceeding with the version upgrade.
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
