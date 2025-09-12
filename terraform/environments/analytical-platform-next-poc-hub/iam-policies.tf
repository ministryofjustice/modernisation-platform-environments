data "aws_iam_policy_document" "athena" {
  statement {
    sid       = "AthenaWorkGroupAccess"
    effect    = "Allow"
    actions   = ["athena:ListWorkGroups"]
    resources = ["*"]
  }
  statement {
    sid    = "AthenaAccess"
    effect = "Allow"
    actions = [
      "athena:GetWorkGroup",
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults"
    ]
    resources = [aws_athena_workgroup.main.arn]
  }
  statement {
    sid    = "AthenaKMSAccess"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [module.s3_mojap_next_poc_athena_query_kms_key.key_arn]
  }
  statement {
    sid    = "AthenaS3BucketAccess"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [module.mojap_next_poc_athena_query_s3_bucket.s3_bucket_arn]
  }
  statement {
    sid    = "AthenaS3ObjectAccess"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["${module.mojap_next_poc_athena_query_s3_bucket.s3_bucket_arn}/*"]
  }
  statement {
    sid    = "GlueAccess"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:SearchTables"
    ]
    resources = ["*"]
  }
  statement {
    sid       = "LakeFormationAccess"
    effect    = "Allow"
    actions   = ["lakeformation:GetDataAccess"]
    resources = ["*"]
  }
}

module "user_iam_policies" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  for_each = toset(local.users)

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.2.1"

  path   = "/users/"
  name   = each.key
  policy = data.aws_iam_policy_document.athena.json
}

module "athena_access_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.2.1"

  name_prefix = "athena-access"
  policy      = data.aws_iam_policy_document.athena.json
}
