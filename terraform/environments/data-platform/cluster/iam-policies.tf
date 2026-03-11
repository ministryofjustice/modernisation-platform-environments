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
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=277e8947b1267290988e47882d8dc116850929be" # v6.4.0

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
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=277e8947b1267290988e47882d8dc116850929be" # v6.4.0

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
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=277e8947b1267290988e47882d8dc116850929be" # v6.4.0

  name_prefix = "karpenter-sqs-kms"

  policy = data.aws_iam_policy_document.karpenter_sqs_kms.json
}

data "aws_iam_policy_document" "velero_kms" {
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
    resources = [module.velero_kms_key.key_arn]
  }
}

module "velero_kms_iam_policy" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=277e8947b1267290988e47882d8dc116850929be" # v6.4.0

  name_prefix = "velero-kms"

  policy = data.aws_iam_policy_document.velero_kms.json
}
