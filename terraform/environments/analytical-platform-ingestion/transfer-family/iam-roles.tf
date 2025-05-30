module "transfer_server_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.54.1"

  create_role = true

  role_name_prefix  = "transfer-server"
  role_requires_mfa = false

  trusted_role_services = ["transfer.amazonaws.com"]

  custom_role_policy_arns = [
    module.transfer_server_iam_policy.arn,
    "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
  ]
}

module "guard_duty_malware_s3_scan_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.44.1"

  create_role = true

  role_name         = "guard-duty-malware-transfer-${local.environment}-scan"
  role_requires_mfa = false

  trusted_role_services = ["malware-protection-plan.guardduty.amazonaws.com"]

  custom_role_policy_arns = [module.guard_duty_s3_malware_protection_iam_policy.arn]
}
