resource "aws_s3_bucket" "cross_account_patches" {
  count         = var.environment == "development" ? 1 : 0
  bucket        = "${var.application}-${var.environment}-${local.os}-patches"
  force_destroy = true
}
resource "aws_s3_bucket_policy" "cross_account_patches" {
  count  = var.environment == "development" ? 1 : 0
  bucket = aws_s3_bucket.cross_account_patches[0].id
  policy = data.aws_iam_policy_document.cross_account_patches[0].json
}

data "aws_iam_policy_document" "cross_account_patches" {
  count = var.environment == "development" ? 1 : 0

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
      aws_s3_bucket.cross_account_patches[0].arn,
      "${aws_s3_bucket.cross_account_patches[0].arn}/*",
    ]

    principals {
      identifiers = tolist(var.instance_roles)
      type        = "AWS"
    }
  }
}

resource "aws_s3_bucket" "patch_logs" {
  bucket        = "${var.application}-${var.environment}-${local.os}-patch-logs"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "patch_logs" {
  bucket = aws_s3_bucket.patch_logs.id
  policy = data.aws_iam_policy_document.patch_logs.json
}

data "aws_iam_policy_document" "patch_logs" {
  statement {
    sid    = "PatchManagerLogs"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetEncryptionConfiguration",
    ]

    resources = [
      aws_s3_bucket.patch_logs.arn,
      "${aws_s3_bucket.patch_logs.arn}/*",
    ]

    principals {
      identifiers = tolist(var.instance_roles)
      type        = "AWS"
    }
  }
}

data "aws_caller_identity" "current" {}
