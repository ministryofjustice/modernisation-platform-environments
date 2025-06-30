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
    # resources = [module.eks_cluster_logs_kms.key_arn]
    resources = [data.aws_kms_key.eks_logs.arn]
  }
}

# module "eks_cluster_logs_kms_access_iam_policy" {
#   #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
#   #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

#   source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
#   version = "5.58.0"

#   name_prefix = "eks-cluster-logs-kms-access"

#   policy = data.aws_iam_policy_document.eks_cluster_logs_kms_access.json

#   tags = local.tags
# }

# data "aws_iam_policy_document" "karpenter_sqs_kms_access" {
#   statement {
#     sid    = "AllowKMS"
#     effect = "Allow"
#     actions = [
#       "kms:Encrypt*",
#       "kms:Decrypt*",
#       "kms:ReEncrypt*",
#       "kms:GenerateDataKey*",
#       "kms:Describe*"
#     ]
#     resources = [module.karpenter_sqs_kms.key_arn]
#   }
# }

# module "karpenter_sqs_kms_access_iam_policy" {
#   #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
#   #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

#   source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
#   version = "5.58.0"

#   name_prefix = "karpenter-sqs-kms-access"

#   policy = data.aws_iam_policy_document.karpenter_sqs_kms_access.json

#   tags = local.tags
# }

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
  version = "5.58.0"

  name_prefix = "amazon-prometheus-proxy"

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
  version = "5.58.0"

  name_prefix = "managed-prometheus-kms-access"

  policy = data.aws_iam_policy_document.managed_prometheus_kms_access.json

  tags = local.tags
}
