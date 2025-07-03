# AWS Transfer Service


resource "aws_iam_role" "transfer_role" {
  count = local.build_transfer ? 1 : 0
  name = "transfer-access-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "transfer_policy" {
  count = local.build_transfer ? 1 : 0
  name = "transfer-access-policy"
  role = aws_iam_role.transfer_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.s3_bucket["inbound"].bucket.arn,
          "${module.s3_bucket["inbound"].bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = local.laa_general_kms_arn
      }
    ]
  })
}
