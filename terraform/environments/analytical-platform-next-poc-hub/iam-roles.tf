module "lakeformation_registration_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.2.1"

  name            = "lakeformation-registration"
  use_name_prefix = "false"

  trust_policy_permissions = {
    TrustRoleAndServiceToAssume = {
      actions = [
        "sts:AssumeRole",
        "sts:SetContext"
      ]
      principals = [{
        type        = "Service"
        identifiers = ["lakeformation.amazonaws.com"]
      }]
    }
  }

  create_inline_policy = true
  inline_policy_permissions = {
    S3BucketAccess = {
      effect    = "Allow"
      actions   = ["s3:ListBucket"]
      resources = ["*"]
    }
    S3ObjectAccess = {
      effect    = "Allow"
      actions   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
      resources = ["*"]
    }
  }
}
