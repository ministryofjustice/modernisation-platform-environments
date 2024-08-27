data "aws_iam_policy_document" "amazon_managed_grafana_remote_cloudwatch" {
  statement {
    sid     = "AllowAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [
      for account in local.all_aws_accounts : format("arn:aws:iam::%s:role/observability-platform", local.environment_management.account_ids[account])
    ]
  }
}

module "amazon_managed_grafana_remote_cloudwatch_iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.44.0"

  name_prefix = "amazon-managed-grafana-remote-cloudwatch"

  policy = data.aws_iam_policy_document.amazon_managed_grafana_remote_cloudwatch.json
}
