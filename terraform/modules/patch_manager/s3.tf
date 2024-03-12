resource "aws_s3_bucket" "this" {
  bucket        = "${var.application}-${var.environment}-patch-logs"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.bucket_policy_patch_access.json
}

data "aws_iam_policy_document" "bucket_policy_patch_access" {
  statement {
    sid    = "AllowCrossAccountAccessToPatchesAndSSMLogging"
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
      identifiers = [
        "arn:aws:iam::161282055413:role/ec2-instance*",
        "arn:aws:iam::139351334100:role/ec2-instance*",
        "arn:aws:iam::228371063224:role/ec2-instance*",
        "arn:aws:iam::905761223702:role/ec2-instance*"
      ]
      type = "AWS"
    }
  }
}

data "aws_caller_identity" "current" {}