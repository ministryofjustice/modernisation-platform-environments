data "aws_iam_policy_document" "user_jacobwoffenden" {
  statement {
    sid    = "AthenaWorkgroupAccess"
    effect = "Allow"
    actions = [
      "athena:GetWorkGroup",
      "athena:ListWorkGroups"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "AthenaKMSAccess"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt"
    ]
    resources = [module.s3_mojap_next_poc_athena_query_kms_key.key_arn]
  }
  statement {
    sid       = "AthenaS3BucketAccess"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
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
      "glue:GetDatabases"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "GlueTest"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:SearchTables"
    ]
    resources = ["*"]
  }
}

module "user_jacobwoffenden_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.2.1"

  path   = "/users/"
  name   = "jacobwoffenden"
  policy = data.aws_iam_policy_document.user_jacobwoffenden.json
}
