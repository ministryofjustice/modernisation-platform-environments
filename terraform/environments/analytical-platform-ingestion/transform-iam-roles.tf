module "transfer_family_service_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.58.0"

  create_role = true

  role_name         = "transfer-family-service-role"
  role_requires_mfa = false

  trusted_role_services = ["transfer.amazonaws.com"]

  custom_role_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"]
}
