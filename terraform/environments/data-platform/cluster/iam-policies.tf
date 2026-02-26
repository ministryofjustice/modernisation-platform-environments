data "aws_iam_policy_document" "prometheus" {
  statement {
    sid    = "AllowAPS"
    effect = "Allow"
    actions = [
      "aps:RemoteWrite",
      "aps:GetSeries",
      "aps:GetLabels",
      "aps:GetMetricMetadata"
    ]
    resources = [module.prometheus.workspace_arn]
  }
}

module "prometheus_iam_policy" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=581bec52db8ad843eeb8e6ae1103aaeec9787c41" # v6.3.0

  name_prefix = "prometheus"

  policy = data.aws_iam_policy_document.prometheus.json
}

data "aws_iam_policy_document" "eks_logs_kms" {
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
    resources = [module.eks_logs_kms_key.key_arn]
  }
}

module "eks_logs_kms_iam_policy" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=581bec52db8ad843eeb8e6ae1103aaeec9787c41" # v6.3.0

  name_prefix = "eks-logs-kms"

  policy = data.aws_iam_policy_document.eks_logs_kms.json

  tags = local.tags
}

data "aws_iam_policy_document" "karpenter_sqs_kms" {
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
    resources = [module.karpenter_sqs_kms_key.key_arn]
  }
}

module "karpenter_sqs_kms_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.3.0"

  name_prefix = "karpenter-sqs-kms"

  policy = data.aws_iam_policy_document.karpenter_sqs_kms.json
}
