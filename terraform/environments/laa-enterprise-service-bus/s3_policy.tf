#####################################################################################
##################### S3 Bucket policy for Hub2.0 Bucket ############################
#####################################################################################
resource "aws_s3_bucket_policy" "data_cross_account_access" {
  bucket = aws_s3_bucket.data.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::767123802783:role/role_stsassume_oracle_base"
        },
        Action = [
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.data.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.data.bucket}/*"
        ]
      }
    ]
  })
}