
data "aws_iam_policy_document" "user-s3-access" {
  statement {
    sid = "user-s3-access"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:ListBucket"
    ]
    resources = ["${module.s3-bucket.bucket.arn}/*",
    module.s3-bucket.bucket.arn, ]
    principals {
      type = "AWS"
      identifiers = sort([ # sort to avoid plan changes
        "arn:aws:iam::${local.account_id}:root",
        "arn:aws:iam::${local.environment_management.account_ids["core-shared-services-production"]}:root"
      ])
    }
  }
}
