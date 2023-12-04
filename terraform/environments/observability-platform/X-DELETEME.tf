/* 
  This code has been replaced by module.prometheus_roles 
  However first we need to update DPAT EKS to use the new format for the prometheus roles
*/
data "aws_iam_policy_document" "amazon_managed_prometheus" {
  statement {
    sid    = "AllowRemoteWrite"
    effect = "Allow"
    actions = [
      "aps:RemoteWrite",
      "aps:GetSeries",
      "aps:GetLabels",
      "aps:GetMetricMetadata"
    ]
    resources = [module.managed_prometheus.workspace_arn]
  }
}

module "amazon_managed_prometheus_iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.0"

  name_prefix = "amazon-managed-prometheus"

  policy = data.aws_iam_policy_document.amazon_managed_prometheus.json
}

module "data_platform_apps_tools_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.0"

  create_role             = true
  role_name               = "data-platform-apps-and-tools"
  trusted_role_arns       = ["arn:aws:iam::${local.environment_configuration.data_platform_apps_tools_account_id}:root"]
  custom_role_policy_arns = [module.amazon_managed_prometheus_iam_policy.arn]
  role_requires_mfa       = false

  tags = local.tags
}
