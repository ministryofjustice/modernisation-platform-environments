resource "aws_s3_bucket" "this" {
  bucket        = "${var.application}-${var.environment}-patch-log"
  force_destroy = true

}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid    = "AllowLoggingToS3"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetEncryptionConfiguration",
    ]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]

    principals {
      identifiers = ["${data.aws_caller_identity.current.account_id}"]
      type        = "AWS"
    }
  }
}

data "aws_caller_identity" "current" {}
