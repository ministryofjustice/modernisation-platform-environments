module "cross-account-access" {
  source     = "github.com/ministryofjustice/modernisation-platform-terraform-cross-account-access?ref=v2.3.0"
  account_id = "754256621582"
  policy_arn = aws_iam_policy.data_platform_datahub_access.arn
  role_name  = "DatahubProductS3AccessRole"
}

data "aws_iam_policy_document" "data-product-s3-access" {
  statement {
    sid = "CPGetPutBucketAccess"
    actions = [
      "s3:GetObject*",
      "s3:PutObject*",
      "s3:ListBucket*",
    ]
    resources = [
      "${module.s3-bucket.bucket.arn}/*",
      "${module.s3-bucket.bucket.arn}"
    ]
  }
}

resource "aws_iam_policy" "data_platform_datahub_access" {
  name        = "data-platform-datahub-access-${local.environment}"
  path        = "/"
  description = "AWS IAM Policy for managing aws lambda role"
  policy      = data.aws_iam_policy_document.data-product-s3-access.json

}
