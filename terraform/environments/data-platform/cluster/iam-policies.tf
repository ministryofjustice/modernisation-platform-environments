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

data "aws_iam_policy_document" "opencost_prometheus_query" {
  statement {
    sid    = "AllowPrometheusQuery"
    effect = "Allow"
    actions = [
      "aps:QueryMetrics",
      "aps:GetSeries",
      "aps:GetLabels",
      "aps:GetMetricMetadata"
    ]
    resources = [module.prometheus.workspace_arn]
  }
}

module "opencost_prometheus_query_iam_policy" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=277e8947b1267290988e47882d8dc116850929be" # v6.4.0

  name_prefix = "opencost-prometheus-query"

  policy = data.aws_iam_policy_document.opencost_prometheus_query.json
}

data "aws_iam_policy_document" "opencost_spot_instance_data_feed" {
  statement {
    sid    = "SpotDataAccess"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "s3:ListBucket",
      "s3:HeadBucket",
      "s3:HeadObject",
      "s3:List*",
      "s3:Get*"
    ]
    resources = [module.opencost_spot_data_bucket.s3_bucket_arn, "${module.opencost_spot_data_bucket.s3_bucket_arn}/*"]
  }
}

module "opencost_spot_data_iam_policy" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=277e8947b1267290988e47882d8dc116850929be" # v6.4.0

  name_prefix = "opencost-spot-data"

  policy = data.aws_iam_policy_document.opencost_spot_instance_data_feed.json
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
