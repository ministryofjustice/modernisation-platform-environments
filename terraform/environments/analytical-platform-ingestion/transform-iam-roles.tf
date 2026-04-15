module "transfer_family_service_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  create = true

  name            = "transfer-family-service-role"
  use_name_prefix = false

  trust_policy_permissions = {
    AllowTransferService = {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["transfer.amazonaws.com"]
      }]
    }
  }

  policies = {
    aws_transfer_logging = "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
  }
}
