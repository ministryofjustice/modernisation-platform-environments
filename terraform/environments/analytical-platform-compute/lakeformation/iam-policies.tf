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
      "lakeformation:DeleteLFTagExpression"
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
  version = "5.59.0"

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
  version = "5.59.0"

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
  version = "5.59.0"

  name_prefix = "copy-apdp-cadet-metadata-to-compute-"

  policy = data.aws_iam_policy_document.copy_apdp_cadet_metadata_to_compute_policy.json

  tags = local.tags
}
