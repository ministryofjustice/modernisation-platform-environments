module "eks_cluster_logs_kms_access_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.2.3"

  name        = "eks-cluster-logs-kms-access20240520163412675900000001"
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
  version = "6.2.3"

  name        = "karpenter-sqs-kms-access20240625125618373200000001"
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
  version = "6.2.3"

  name        = "amazon-prometheus-proxy20240521075058823800000001"
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
  version = "6.2.3"

  name        = "managed-prometheus-kms-access20240521093109516600000001"
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
  version = "6.2.3"

  name        = "ecr-pull-through-cache20250724171726658700000001"
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
  version = "6.2.3"

  name        = "velero-kms-access20250820143113414500000001"
  description = "IAM Policy"

  policy = data.aws_iam_policy_document.velero_kms_access.json

  tags = local.tags
}
