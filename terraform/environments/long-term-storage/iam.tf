#tfsec:ignore:aws-iam-no-user-attached-policies 
#tfsec:ignore:AWS273
resource "aws_iam_user" "s3_user" {
  #checkov:skip=CKV_AWS_273: "Skipping as tfsec check is also set to ignore"
  name = "s3-access-user"
}

resource "aws_iam_policy" "s3_read_only_policy" {
  # checkov:skip=CKV_AWS_40:"Directly attaching the policy makes more sense here"
  name        = "S3ReadOnlyOsptBucketPolicy"
  description = "Read-only access to ospt bucket"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.ospt_transfer.arn}",
          "${aws_s3_bucket.ospt_transfer.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "s3_user_policy_attach" {
  #tfsec:ignore:aws-iam-no-user-attached-policies
  #checkov:skip=CKV_AWS_40: "Skipping as tfsec check is also ignored"
  user       = aws_iam_user.s3_user.name
  policy_arn = aws_iam_policy.s3_read_only_policy.arn
}

resource "aws_secretsmanager_secret" "s3_user_secret" {
  # checkov:skip=CKV2_AWS_57:Auto rotation not possible
  # checkov:skip=CKV_AWS_149:No requirement currently to encrypt this secret with customer-managed KMS key
  name        = "s3-user-credentials"
  description = "Access and secret key for S3 IAM user"
}