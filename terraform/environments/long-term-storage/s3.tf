resource "aws_s3_bucket" "ospt_transfer" {
  bucket = "ospt-transfer"
}

# Policy granting read/write (no delete) access to the bucket
data "aws_iam_policy_document" "s3_read_write_policy" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.ospt_transfer.arn,
      "${aws_s3_bucket.ospt_transfer.arn}/*"
    ]
  }
}

# Role for Civica
resource "aws_iam_role" "civica_role" {
  name = "civica-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.modernisation_platform_account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "civica_s3_access" {
  name = "CivicaS3Access"
  role = aws_iam_role.civica_role.id
  policy = data.aws_iam_policy_document.s3_read_write_policy.json
}

# Role for Node4
resource "aws_iam_role" "node4_role" {
  name = "node4-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::<EXTERNAL_ACCOUNT_ID>:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "node4_s3_access" {
  name = "Node4S3Access"
  role = aws_iam_role.node4_role.id
  policy = data.aws_iam_policy_document.s3_read_write_policy.json
}
