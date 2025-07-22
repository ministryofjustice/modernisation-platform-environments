data "aws_iam_policy_document" "glue_crawler" {
  statement {
    sid       = "AllowKMS"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [module.kms_key.key_arn]
  }
  statement {
    sid       = "AllowS3"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${module.s3_bucket.s3_bucket_arn}/*"]
  }
}

module "glue_crawler_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.59.0"

  name_prefix = "glue-crawler"
  policy      = data.aws_iam_policy_document.glue_crawler.json
}
