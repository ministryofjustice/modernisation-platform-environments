module "transfer_server_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.59.0"

  create_role = true

  role_name_prefix  = "transfer-server"
  role_requires_mfa = false

  trusted_role_services = ["transfer.amazonaws.com"]

  custom_role_policy_arns = [
    module.transfer_server_iam_policy.arn,
    "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
  ]
}
