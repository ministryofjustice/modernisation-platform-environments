module "vpc_flow_logs_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.37.1"

  create_role = true

  role_name_prefix  = "vpc-flow-logs"
  role_requires_mfa = false

  trusted_role_services = ["vpc-flow-logs.amazonaws.com"]

  custom_role_policy_arns = [module.vpc_flow_logs_iam_policy.arn]
}
