data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAM Role
resource "aws_iam_role" "sftp_user_role" {
  name               = "sftp-user-role-${var.user_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# IAM Policy
resource "aws_iam_policy" "sftp_user_policy" {
  name   = "sftp-user-policy-${var.user_name}"
  policy = data.aws_iam_policy_document.sftp_user_policy.json
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "attach_user_policy" {
  role       = aws_iam_role.sftp_user_role.name
  policy_arn = aws_iam_policy.sftp_user_policy.arn
}

# SFTP User
resource "aws_transfer_user" "this" {
  server_id           = var.server_id
  user_name           = var.user_name
  role                = aws_iam_role.sftp_user_role.arn
  home_directory      = "/"
  home_directory_type = "LOGICAL"

  home_directory_mappings {
    entry  = "/"
    target = "/${var.s3_bucket}/${var.user_name}"
  }

  tags = {
    Name = var.user_name
  }
}

# --- User-specific Resources ---
data "aws_iam_policy_document" "sftp_user_policy" {
  statement {
    sid       = "ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.s3_bucket}"]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = [var.user_name, "${var.user_name}/*"]
    }
  }

  statement {
    sid    = "FullAccessToUserFolder"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObjectTagging",
      "s3:PutObjectTagging",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
      "s3:PutObjectAcl"
    ]
    resources = ["arn:aws:s3:::${var.s3_bucket}/${var.user_name}/*"]
  }

  statement {
    sid    = "KMSAccessForEncryptedS3"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [
      var.kms_key_arn
    ]
  }
}

