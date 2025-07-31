#####################################################################################
## IAM Role for CCMS Instance for mounting extract data S3 bucket ###################
#####################################################################################

resource "aws_iam_role" "ccms_cross_account_s3_read" {
  name = "${local.application_name_short}-${local.environment}-ccms-cross-account-s3-read"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::767123802783:role/role_stsassume_oracle_base"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-ccms-cross-account-s3-read"
    }
  )
}

resource "aws_iam_policy" "ccms_cross_account_s3_read_policy" {
  name = "${local.application_name_short}-${local.environment}-ccms-cross-account-s3-read-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:ListBucketVersions"
        ],
        Resource = [
          "${aws_s3_bucket.data.arn}",
          "${aws_s3_bucket.data.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ccms_cross_account_s3_read_attach" {
  role       = aws_iam_role.ccms_cross_account_s3_read.name
  policy_arn = aws_iam_policy.ccms_cross_account_s3_read_policy.arn
}




