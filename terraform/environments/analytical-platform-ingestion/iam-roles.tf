module "transfer_server_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "6.2.3"

  create_role = true

  role_name_prefix  = "transfer-server"
  role_requires_mfa = false

  trusted_role_services = ["transfer.amazonaws.com"]

  custom_role_policy_arns = [
    module.transfer_server_iam_policy.arn,
    "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
  ]
}

module "datasync_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "6.2.3"

  create_role = true

  role_name_prefix  = "datasync"
  role_requires_mfa = false

  trusted_role_services = ["datasync.amazonaws.com"]

  custom_role_policy_arns = [module.datasync_iam_policy.arn]
}

module "datasync_replication_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "6.2.3"

  create_role = true

  role_name         = "datasync-replication"
  role_requires_mfa = false

  trusted_role_services = ["s3.amazonaws.com"]

  custom_role_policy_arns = [module.datasync_replication_iam_policy.arn]
}

module "datasync_opg_replication_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "6.2.3"

  create_role = true

  role_name         = "datasync-opg-ingress-${local.environment}-replication"
  role_requires_mfa = false

  trusted_role_services = ["s3.amazonaws.com"]

  custom_role_policy_arns = [module.datasync_opg_replication_iam_policy.arn]
}

# Guard Duty Malware Role

module "guard_duty_malware_s3_scan_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "6.2.3"

  create_role = true

  role_name         = "guard-duty-malware-${local.environment}-scan"
  role_requires_mfa = false

  trusted_role_services = ["malware-protection-plan.guardduty.amazonaws.com"]

  custom_role_policy_arns = [module.guard_duty_s3_malware_protection_iam_policy.arn]
}

module "datasync_laa_data_analysis_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  count = local.environment == "production" ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "6.2.3"

  create_role = true

  role_name         = "datasync-laa-data-analysis"
  role_requires_mfa = false

  trusted_role_services = ["datasync.amazonaws.com"]

  custom_role_policy_arns = [module.laa_data_analysis_iam_policy[0].arn]
}

module "laa_data_analysis_replication_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  count = local.environment == "production" ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "6.2.3"

  create_role = true

  role_name         = "laa-data-analysis-${local.environment}-replication"
  role_requires_mfa = false

  trusted_role_services = ["s3.amazonaws.com", "batchoperations.s3.amazonaws.com"] # I want to replicate after scanning only, so need to do it as a batch job

  custom_role_policy_arns = [module.laa_data_analysis_replication_iam_policy[0].arn]
}
