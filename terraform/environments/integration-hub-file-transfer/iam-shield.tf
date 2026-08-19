module "iam_role_shield_srt_access" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.8.0"

  create          = true
  use_name_prefix = true
  name            = "shield-srt-access"

  trust_policy_permissions = {
    AllowShieldService = {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["drt.shield.amazonaws.com"]
      }]
    }
  }

  policies = {
    shield_srt_access = "arn:aws:iam::aws:policy/service-role/AWSShieldDRTAccessPolicy"
  }

  tags = local.tags
}