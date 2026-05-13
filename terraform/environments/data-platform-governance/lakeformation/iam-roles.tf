module "lakeformation_access_iam_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role?ref=1d73bcb359419e1b41872ac5ccaf8808b8f1150e" # v6.6.0

  name            = "lakeformation-access"
  use_name_prefix = false


  trust_policy_permissions = {
    TrustRoleAndServiceToAssume = {
      actions = [
        "sts:AssumeRole",
        "sts:SetContext",
        "sts:TagSession",
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
      effect = "Allow"
      actions = [
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:PutObject"
      ]
      resources = ["*"]
    }
  }
}
