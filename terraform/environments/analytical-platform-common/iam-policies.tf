data "aws_iam_policy_document" "ecr_access" {
  statement {
    sid    = "AllowECRRepositoryPermissions"
    effect = "Allow"
    actions = [
      "ecr:CreateRepository",
      "ecr:GetRepositoryPolicy",
      "ecr:SetRepositoryPolicy"
    ]
    resources = ["arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/*"]
  }
  statement {
    sid       = "DenyECRRepositoryPermissions"
    effect    = "Deny"
    actions   = ["ecr:DeleteRepository"]
    resources = ["arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/*"]
  }
}

module "ecr_iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.48.0"

  name_prefix = "ecr-access"

  policy = data.aws_iam_policy_document.ecr_access.json
}
