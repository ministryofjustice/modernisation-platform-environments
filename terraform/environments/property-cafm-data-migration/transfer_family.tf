# Attach an IAM policy to the role for S3 access
resource "aws_iam_role_policy" "sftp_policy" {
  name = "sftp-s3-policy"
  role = aws_iam_role.sftp_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${aws_s3_bucket.CAFM.bucket}"
      },
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObjectVersion",
          "s3:DeleteObject",
          "s3:GetObjectVersion"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${aws_s3_bucket.CAFM.bucket}/*"
      }
    ]
  })
}

# Create the AWS Transfer Family SFTP server
resource "aws_transfer_server" "sftp_server" {
# checkov:skip=CKV_AWS_164: "using public endpoint option for AWS Transfer"
  identity_provider_type = "SERVICE_MANAGED"
  endpoint_type = "PUBLIC"
  tags = {
    Name = "CAFM SFTP Server"
  }
  security_policy_name = "TransferSecurityPolicy-2024-01"
}

# Create an SFTP user
resource "aws_transfer_user" "sftp_user" {
  server_id = aws_transfer_server.sftp_server.id
  user_name = "sftp-user"
  role      = aws_iam_role.sftp_role.arn
  home_directory = "/${aws_s3_bucket.CAFM.bucket}"
}


# Adding SFTP ssh key
resource "aws_transfer_ssh_key" "sftp-ssh-key" {
  server_id = aws_transfer_server.sftp_server.id
  user_name = aws_transfer_user.sftp_user.user_name
  body = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDaa4nS966z8WHgWZ0n2pDr+0/BNf06mTW4CdD6RJ1qIDIVVv55P4BN6dBSJVqDfkuOg0urG06LsE4FiRvYGViN4/fHc5mU0Jw0r6Gzu+g+yC7zLpV4LIhjHLxgEv86GzxIF3WjKDalbW0SrNyxoxJD6IKxr/IKLMAwsuVNSIXA18IZZwhdfvrT36YOBW+3+mSAblnOZkZh4ltpA7ATa7GSnQPFnoBmCT//wA8t/7aZ+OmN6ytERMiBpjI8DjFuUBlCHPKeSBsK2WGuXiNLrRocCqkAO3WpX5kmC8x3SXQOsjsuWRTloOycBFRdzNCL7RKIdS3cqyrkGpdJr4H7t0O/lYenVews5Plgau+H4/nnBIjIXmdLq8He6G0r/nxcIeTyTOpYwQ0pw+WzNQQJPeWmGnzOjEaiPJbZ/GHwI6j67KzIVcmYYeyfJnrF14VEj+tJSlsn8Rl6+Bu/nTtYjVMlLZOwqH33HQrSUmiycukN4CWc69LYg1hezfbABkVKRFcRcfl4v0HzDJ2wqQS5NU2m8NQWL18zqi4hy5X+Hx4NyAIRCqX3+7YhEpfQrbYVvGjILGFSc4O0PwtW4jHmmjIresPfz7QXoXRlAe2aAQlWYGfBVP3y0xMNk0QGoEJHDjOgVCsmHvUtC62qfdadqhPNMY9pf3YQ10PBfkIq96LDAQ== jyotiranjan.nayak@MJ005734"
}

data "aws_iam_policy_document" "sftp_access" {
  statement {
    sid    = "AllowSftpFromWhitelistedIps"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"] # Or specific ARNs if you want to restrict to a service principal
    }
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "transfer:Describe*",
      "transfer:List*",
      "transfer:SendWorkflowStepState",
    ]
    resources = ["*"]
    condition {
      test     = "IpAddress"
      values   = ["192.168.0.58/32",
                  "94.195.119.194/32",
                  "100.64.11.172/32"] # ✅ Only allow specific IPs
      variable = "aws:SourceIP"
    }
  }
}

resource "aws_iam_policy" "sftp_policy" {
  name   = "sftp-access-policy"
  policy = data.aws_iam_policy_document.sftp_access.json
}

resource "aws_iam_role" "sftp_role" {
  name               = "sftp-access-role"
  assume_role_policy = data.aws_iam_policy_document.sftp_access_assume_role.json
}

data "aws_iam_policy_document" "sftp_access_assume_role" {
  statement {
    sid    = "AllowAssumeRole"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "sftp_role_attachment" {
  role       = aws_iam_role.sftp_role.name
  policy_arn = aws_iam_policy.sftp_policy.arn
}