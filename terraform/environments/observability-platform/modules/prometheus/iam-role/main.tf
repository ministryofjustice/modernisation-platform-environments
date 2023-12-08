data "aws_iam_policy_document" "aps" {
  statement {
    sid    = "AllowRemoteWrite"
    effect = "Allow"
    actions = [
      "aps:RemoteWrite",
      "aps:GetSeries",
      "aps:GetLabels",
      "aps:GetMetricMetadata"
    ]
    resources = [var.prometheus_workspace_arn]
  }
}

module "iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.0"

  name_prefix = "${var.name}-prometheus"

  policy = data.aws_iam_policy_document.aps.json
}

module "iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.0"

  create_role             = true
  role_name               = "${var.name}-prometheus"
  trusted_role_arns       = ["arn:aws:iam::${var.account_id}:root"]
  custom_role_policy_arns = [module.iam_policy.arn]
  role_requires_mfa       = false
}
