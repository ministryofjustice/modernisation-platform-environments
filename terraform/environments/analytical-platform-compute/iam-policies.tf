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

module "eks_cluster_logs_kms_access_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.41.0"

  name_prefix = "eks-cluster-logs-kms-access"

  policy = data.aws_iam_policy_document.eks_cluster_logs_kms_access.json
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
  version = "5.41.0"

  name_prefix = "karpenter-sqs-kms-access"

  policy = data.aws_iam_policy_document.karpenter_sqs_kms_access.json
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
    resources = [aws_prometheus_workspace.main.arn]
  }
}

module "amazon_prometheus_proxy_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.41.0"

  name_prefix = "amazon-prometheus-proxy"

  policy = data.aws_iam_policy_document.amazon_prometheus_proxy.json
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
  version = "5.41.0"

  name_prefix = "managed-prometheus-kms-access"

  policy = data.aws_iam_policy_document.managed_prometheus_kms_access.json
}

data "aws_iam_policy_document" "mlflow" {
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
    resources = [module.mlflow_s3_kms.key_arn]
  }
  statement {
    sid     = "AllowS3List"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      module.mlflow_bucket.s3_bucket_arn,
      "arn:aws:s3:::${local.environment_configuration.mlflow_s3_bucket_name}"
    ]
  }
  statement {
    sid    = "AllowS3Write"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${module.mlflow_bucket.s3_bucket_arn}/*",
      "arn:aws:s3:::${local.environment_configuration.mlflow_s3_bucket_name}"
    ]
  }
}

module "mlflow_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.41.0"

  name_prefix = "mlflow"

  policy = data.aws_iam_policy_document.mlflow.json
}

data "aws_iam_policy_document" "gha_mojas_airflow" {
  statement {
    sid       = "EKSAccess"
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = [module.eks.cluster_arn]
  }
}

module "gha_mojas_airflow_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.41.0"

  name_prefix = "github-actions-mojas-airflow"

  policy = data.aws_iam_policy_document.gha_mojas_airflow.json
}

data "aws_iam_policy_document" "analytical_platform_share_policy" {

  statement {
    effect = "Allow"
    actions = [
      "lakeformation:GrantPermissions",
      "lakeformation:RevokePermissions",
      "lakeformation:BatchGrantPermissions",
      "lakeformation:BatchRevokePermissions",
      "lakeformation:RegisterResource",
      "lakeformation:DeregisterResource",
      "lakeformation:ListPermissions",
      "lakeformation:DescribeResource",

    ]
    resources = [
      "arn:aws:lakeformation:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:catalog:${data.aws_caller_identity.current.account_id}"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:PutRolePolicy",
      "iam:CreateServiceLinkedRole"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/lakeformation.amazonaws.com/AWSServiceRoleForLakeFormationDataAccess"
    ]
  }
  # Needed for LakeFormationAdmin to check the presense of the Lake Formation Service Role
  statement {
    effect = "Allow"
    actions = [
      "iam:GetRolePolicy",
      "iam:GetRole",
      "lakeformation:GetDataAccess",
      "glue:*",
      "lakeformation:*",
      "sso:*",
      "iam:*",
      "sso-directory:*",
      "athena:*",
      "s3:*"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ram:CreateResourceShare",
      "ram:DeleteResourceShare"
    ]
    resources = [
      "arn:aws:ram:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:resource-share/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetPartition"
    ]
    resources = ["*"]
  }
}

module "analytical_platform_lake_formation_share_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.41.0"

  name_prefix = "analytical-platform-lake-formation-sharing-policy"

  policy = data.aws_iam_policy_document.analytical_platform_share_policy.json
}
