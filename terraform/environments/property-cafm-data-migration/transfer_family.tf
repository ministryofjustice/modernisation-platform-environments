# --- SFTP Server ---
resource "aws_transfer_server" "sftp_server" {
# checkov:skip=CKV_AWS_164: "using public endpoint option for AWS Transfer"
  identity_provider_type = "SERVICE_MANAGED"
  endpoint_type          = "PUBLIC"
  security_policy_name   = "TransferSecurityPolicy-2024-01"
  logging_role  = aws_iam_role.transfer_logging.arn
  tags = {
    Name = "CAFM SFTP Server"
  }
}

resource "aws_iam_role" "transfer_logging" {
  name = "TransferFamilyLoggingRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "transfer.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "transfer_logging_policy" {
  role       = aws_iam_role.transfer_logging.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
}


# --- Common Assume Role Policy Document ---
data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "AllowAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
  }
}

# --- SFTP Server-Level Access Policy (if needed globally) ---
data "aws_iam_policy_document" "sftp_access" {
  statement {
    sid     = "AllowSftpFromWhitelistedIps"
    effect  = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "transfer:Describe*",
      "transfer:List*",
      "transfer:SendWorkflowStepState"
    ]
    resources = ["*"]

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = ["94.195.119.194/32"]
    }
  }
}

resource "aws_iam_policy" "sftp_access_policy" {
  name   = "sftp-access-policy"
  policy = data.aws_iam_policy_document.sftp_access.json
}

resource "aws_iam_role" "sftp_role" {
  name               = "sftp-access-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "sftp_role_attachment" {
  role       = aws_iam_role.sftp_role.name
  policy_arn = aws_iam_policy.sftp_access_policy.arn
}

# --- User-specific Resources ---
data "aws_iam_policy_document" "sftp_user_policy" {
  statement {
    sid = "ListBucket"
    effect = "Allow"
    actions = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.CAFM.bucket}"]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["test_user1", "test_user1/*"]
    }
  }

  statement {
    sid = "FullAccessToUserFolder"
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
    resources = ["arn:aws:s3:::${aws_s3_bucket.CAFM.bucket}/test_user1/*"]
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
        aws_kms_key.sns_kms.arn
    ]
    }
}

resource "aws_iam_policy" "sftp_user_policy" {
  name   = "sftp-user-policy"
  policy = data.aws_iam_policy_document.sftp_user_policy.json
}


# ------------------------
# IAM Role for Transfer Family
# ------------------------
resource "aws_iam_role" "sftp_user_role" {
  name               = "sftp-user-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "attach_user_policy" {
  role       = aws_iam_role.sftp_user_role.name
  policy_arn = aws_iam_policy.sftp_user_policy.arn
}

# ------------------------
# Transfer User
# ------------------------
resource "aws_transfer_user" "sftp_user" {
  server_id            = aws_transfer_server.sftp_server.id
  user_name            = "test_user1"
  role                 = aws_iam_role.sftp_user_role.arn
  home_directory       = "/"
  home_directory_type  = "LOGICAL"

  home_directory_mappings {
    entry  = "/"
    target = "/${ aws_s3_bucket.CAFM.bucket}/test_user1"
  }
}

# ------------------------
# SSH Key for SFTP Login
# ------------------------
resource "aws_transfer_ssh_key" "sftp_ssh_key" {
  server_id = aws_transfer_server.sftp_server.id
  user_name = aws_transfer_user.sftp_user.user_name
  body      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDaa4nS966z8WHgWZ0n2pDr+0/BNf06mTW4CdD6RJ1qIDIVVv55P4BN6dBSJVqDfkuOg0urG06LsE4FiRvYGViN4/fHc5mU0Jw0r6Gzu+g+yC7zLpV4LIhjHLxgEv86GzxIF3WjKDalbW0SrNyxoxJD6IKxr/IKLMAwsuVNSIXA18IZZwhdfvrT36YOBW+3+mSAblnOZkZh4ltpA7ATa7GSnQPFnoBmCT//wA8t/7aZ+OmN6ytERMiBpjI8DjFuUBlCHPKeSBsK2WGuXiNLrRocCqkAO3WpX5kmC8x3SXQOsjsuWRTloOycBFRdzNCL7RKIdS3cqyrkGpdJr4H7t0O/lYenVews5Plgau+H4/nnBIjIXmdLq8He6G0r/nxcIeTyTOpYwQ0pw+WzNQQJPeWmGnzOjEaiPJbZ/GHwI6j67KzIVcmYYeyfJnrF14VEj+tJSlsn8Rl6+Bu/nTtYjVMlLZOwqH33HQrSUmiycukN4CWc69LYg1hezfbABkVKRFcRcfl4v0HzDJ2wqQS5NU2m8NQWL18zqi4hy5X+Hx4NyAIRCqX3+7YhEpfQrbYVvGjILGFSc4O0PwtW4jHmmjIresPfz7QXoXRlAe2aAQlWYGfBVP3y0xMNk0QGoEJHDjOgVCsmHvUtC62qfdadqhPNMY9pf3YQ10PBfkIq96LDAQ== jyotiranjan.nayak@MJ005734"

  depends_on = [aws_transfer_user.sftp_user]
}

# ------------------------
# Create S3 Folder Placeholder
# ------------------------
resource "aws_s3_object" "CAFM" {
  bucket   = aws_s3_bucket.CAFM.bucket
  key      = "test_user1/.keep"
  content  = ""
}
