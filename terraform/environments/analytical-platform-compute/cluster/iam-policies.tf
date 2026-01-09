module "eks_cluster_logs_kms_access_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.3.0"

  name        = "eks-cluster-logs-kms-access20240522102606755500000004"
  description = "IAM Policy"

  policy = data.aws_iam_policy_document.eks_cluster_logs_kms_access.json

  tags = local.tags
}

data "aws_iam_policy_document" "eks_cluster_logs_kms_access" {
  statement {
    sid    = "AllowKMS"
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = [module.eks_cluster_logs_kms.key_arn]
  }
}

data "aws_iam_policy_document" "karpenter_sqs_kms_access" {
  statement {
    sid    = "AllowKMS"
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = [module.karpenter_sqs_kms.key_arn]
  }
}

module "karpenter_sqs_kms_access_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.3.0"

  name        = "karpenter-sqs-kms-access2024062615572751670000000e"
  description = "IAM Policy"

  policy = data.aws_iam_policy_document.karpenter_sqs_kms_access.json

  tags = local.tags
}

data "aws_iam_policy_document" "amazon_prometheus_proxy" {
  statement {
    sid    = "AllowAPS"
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

module "amazon_prometheus_proxy_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.3.0"

  name        = "amazon-prometheus-proxy20240522102759795300000017"
  description = "IAM Policy"

  policy = data.aws_iam_policy_document.amazon_prometheus_proxy.json

  tags = local.tags
}

data "aws_iam_policy_document" "managed_prometheus_kms_access" {
  statement {
    sid    = "AllowKMS"
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = [module.managed_prometheus_kms.key_arn]
  }
}

module "managed_prometheus_kms_access_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.3.0"

  name        = "managed-prometheus-kms-access20240522102621280000000012"
  description = "IAM Policy"

  policy = data.aws_iam_policy_document.managed_prometheus_kms_access.json

  tags = local.tags
}


data "aws_iam_policy_document" "ecr_pull_through_cache" {
  statement {
    sid    = "AllowECRPullThroughCache"
    effect = "Allow"
    actions = [
      "ecr:BatchImportUpstreamImage",
      "ecr:CreateRepository",
      "ecr:TagResource"
    ]
    resources = [
      "arn:aws:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/ecr/*",
      "arn:aws:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/github/*"
    ]
  }
}

module "ecr_pull_through_cache_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.3.0"

  name        = "ecr-pull-through-cache20250724174113618600000002"
  description = "IAM Policy"

  policy = data.aws_iam_policy_document.ecr_pull_through_cache.json

  tags = local.tags
}

data "aws_iam_policy_document" "velero_kms_access" {
  statement {
    sid    = "AllowKMS"
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = [module.velero_kms.key_arn]
  }
}

module "velero_kms_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.3.0"

  name        = "velero-kms-access20250821153908350800000003"
  description = "IAM Policy"

  policy = data.aws_iam_policy_document.velero_kms_access.json

  tags = local.tags
}
