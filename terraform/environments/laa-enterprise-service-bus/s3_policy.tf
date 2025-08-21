#####################################################################################
##################### S3 Bucket policy for Hub2.0 Bucket ############################
#####################################################################################
resource "aws_s3_bucket_policy" "data_cross_account_access" {
  bucket = aws_s3_bucket.data.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowCWALambdaReadWrite"
        Effect = "Allow",
        Principal = {
          AWS = [
            aws_iam_role.cwa_extract_lambda_role.arn
          ]
        },
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.data.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.data.bucket}/*"
        ]
      },
      {
        Sid = "AllowReadAccessFromDB"
        Effect = "Allow",
        Principal = {
          AWS = [
            aws_iam_role.ccms_cross_account_s3_read.arn,
            aws_iam_role.maat_cross_account_s3_read.arn
          ]
        },
        Action = [
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:ListBucketVersions"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.data.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.data.bucket}/*"
        ]
      }
    ]
  })
}