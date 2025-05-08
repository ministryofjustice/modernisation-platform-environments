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
  version = "5.55.0"

  name_prefix = "eks-cluster-logs-kms-access"

  policy = data.aws_iam_policy_document.eks_cluster_logs_kms_access.json

  tags = local.tags
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
  version = "5.55.0"

  name_prefix = "karpenter-sqs-kms-access"

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
  version = "5.55.0"

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
  version = "5.55.0"

  name_prefix = "managed-prometheus-kms-access"

  policy = data.aws_iam_policy_document.managed_prometheus_kms_access.json

  tags = local.tags
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
      "arn:aws:s3:::${local.environment_configuration.mlflow_s3_bucket_name}/*"
    ]
  }
}

module "mlflow_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.55.0"

  name_prefix = "mlflow"

  policy = data.aws_iam_policy_document.mlflow.json

  tags = local.tags
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
  version = "5.55.0"

  name_prefix = "github-actions-mojas-airflow"

  policy = data.aws_iam_policy_document.gha_mojas_airflow.json

  tags = local.tags
}

#trivy:ignore:AVD-AWS-0345: test policy for development
data "aws_iam_policy_document" "analytical_platform_share_policy" {
  #checkov:skip=CKV_AWS_110: test policy for development
  #checkov:skip=CKV_AWS_107: test policy for development
  #checkov:skip=CKV_AWS_111: test policy for development
  #checkov:skip=CKV_AWS_356: test policy for development
  #checkov:skip=CKV_AWS_109: test policy for development
  #checkov:skip=CKV_AWS_108: test policy for development
  #checkov:skip=CKV2_AWS_40: test policy for development
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
      "lakeformation:GetDataAccess",
    ]
    resources = ["arn:aws:lakeformation:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:catalog:${data.aws_caller_identity.current.account_id}"]
  }
  statement {
    effect    = "Allow"
    actions   = ["iam:PutRolePolicy"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/lakeformation.amazonaws.com/AWSServiceRoleForLakeFormationDataAccess"]
  }
  # Needed for LakeFormationAdmin to check the presense of the Lake Formation Service Role
  statement {
    effect    = "Allow"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["lakeformation.amazonaws.com"]
    }
  }
  # Needed for creation of Lake Formation Service Role
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
      "s3:*",
      "quicksight:*"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ram:CreateResourceShare",
      "ram:DeleteResourceShare"
    ]
    resources = ["arn:aws:ram:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:resource-share/*"]
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
  version = "5.55.0"

  name_prefix = "analytical-platform-lake-formation-sharing-policy"

  policy = data.aws_iam_policy_document.analytical_platform_share_policy.json

  tags = local.tags
}

data "aws_iam_policy_document" "data_production_mojap_derived_bucket_lake_formation_policy" {
  statement {
    sid    = "AllowS3ReadWriteAPDataProdDerivedTables"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["arn:aws:s3:::mojap-derived-tables/prod/*"]
  }
  statement {
    sid    = "AllowS3AccessAPDataProdDerivedTablesBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = ["arn:aws:s3:::mojap-derived-tables"]
  }
  statement {
    sid    = "AllowLakeFormationCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws-lakeformation-acceleration/*",
      "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws-lakeformation-acceleration/*:log-stream:*"
    ]
  }
}

module "data_production_mojap_derived_bucket_lake_formation_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.55.0"

  name_prefix = "analytical-platform-data-bucket-lake-formation-policy"

  policy = data.aws_iam_policy_document.data_production_mojap_derived_bucket_lake_formation_policy.json

  tags = local.tags
}

data "aws_iam_policy_document" "copy_apdp_cadet_metadata_to_compute_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  statement {
    sid    = "AthenaAccess"
    effect = "Allow"
    actions = [
      "athena:List*",
      "athena:Get*",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution"
    ]
    resources = [
      "arn:aws:athena:eu-west-2:${data.aws_caller_identity.current.account_id}:datacatalog/*",
      "arn:aws:athena:eu-west-2:${data.aws_caller_identity.current.account_id}:workgroup/*"
    ]
  }
  statement {
    sid    = "GlueAccess"
    effect = "Allow"
    actions = [
      "glue:Get*",
      "glue:DeleteTable",
      "glue:DeleteTableVersion",
      "glue:DeleteSchema",
      "glue:DeletePartition",
      "glue:DeleteDatabase",
      "glue:UpdateTable",
      "glue:UpdateSchema",
      "glue:UpdatePartition",
      "glue:UpdateDatabase",
      "glue:CreateTable",
      "glue:CreateSchema",
      "glue:CreatePartition",
      "glue:CreatePartitionIndex",
      "glue:BatchCreatePartition",
      "glue:CreateDatabase"
    ]
    resources = [
      "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:schema/*",
      "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:database/*",
      "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:table/*/*",
      "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:catalog"
    ]
  }
  statement {
    sid    = "GlueFetchMetadataAccess"
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetPartition"
    ]
    resources = ["arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:*"]
  }
  statement {
    sid    = "AthenaQueryBucketAccess"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload",
      "s3:PutObject"
    ]
    resources = [
      module.mojap_compute_athena_query_results_bucket_eu_west_2.s3_bucket_arn,
      "${module.mojap_compute_athena_query_results_bucket_eu_west_2.s3_bucket_arn}/*"
    ]
  }
  statement {
    sid    = "AlterLFTags"
    effect = "Allow"
    actions = [
      "lakeformation:ListLFTags",
      "lakeformation:GetLFTag",
      "lakeformation:CreateLFTag",
      "lakeformation:UpdateLFTag",
      "lakeformation:AddLFTagsToResource",
      "lakeformation:RemoveLFTagsFromResource",
      "lakeformation:GetResourceLFTags",
      "lakeformation:SearchTablesByLFTags",
      "lakeformation:SearchDatabasesByLFTags",
    ]
    resources = ["*"]
  }

}

module "copy_apdp_cadet_metadata_to_compute_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.55.0"

  name_prefix = "copy-apdp-cadet-metadata-to-compute-"

  policy = data.aws_iam_policy_document.copy_apdp_cadet_metadata_to_compute_policy.json

  tags = local.tags
}

data "aws_iam_policy_document" "gha_moj_ap_airflow" {
  statement {
    sid    = "MWAAKMSAccess"
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = [module.mwaa_kms.key_arn]
  }
  statement {
    sid    = "MWAABucketAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [module.mwaa_bucket.s3_bucket_arn]
  }
  statement {
    sid    = "MWAAS3WriteAccess"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["${module.mwaa_bucket.s3_bucket_arn}/*"]
  }
  statement {
    sid       = "EKSAccess"
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = [module.eks.cluster_arn]
  }
}

module "gha_moj_ap_airflow_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.55.0"

  name = "github-actions-ministryofjustice-analytical-platform-airflow"

  policy = data.aws_iam_policy_document.gha_moj_ap_airflow.json

  tags = local.tags
}
