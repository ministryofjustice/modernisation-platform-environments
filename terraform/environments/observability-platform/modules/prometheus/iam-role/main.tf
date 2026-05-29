data "aws_prometheus_workspaces" "observability_platform" {
  alias_prefix = "observability-platform"
}

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
    resources = [one(data.aws_prometheus_workspaces.observability_platform.arns)]
  }
}

module "iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.52.2"

  name_prefix = "${var.name}-prometheus"

  policy = data.aws_iam_policy_document.aps.json
}

module "iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.1"

  name            = "${var.name}-prometheus"
  use_name_prefix = false

  trust_policy_permissions = {
    AllowAssumeRole = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${var.account_id}:root"]
      }]
    }
  }

  policies = {
    prometheus = module.iam_policy.arn
  }
}
