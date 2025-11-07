#####################################################################################
##################### S3 Bucket policy for Hub2.0 Bucket ############################
#####################################################################################
resource "aws_s3_bucket_policy" "patch_data_cross_account_access" {
  count  = local.environment == "test" ? 1 : 0
  bucket = aws_s3_bucket.patch_data[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowCWALambdaReadWrite"
        Effect = "Allow",
        Principal = {
          AWS = [
            aws_iam_role.patch_cwa_extract_lambda_role[0].arn
          ]
        },
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.patch_data[0].bucket}",
          "arn:aws:s3:::${aws_s3_bucket.patch_data[0].bucket}/*"
        ]
      },
      {
        Sid    = "AllowReadAccessFromDB"
        Effect = "Allow",
        Principal = {
          AWS = [
            "arn:aws:iam::730335523459:role/role_stsassume_oracle_base"
          ]
        },
        Action = [
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:ListBucketVersions",
          "s3:PutObject"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.patch_data[0].bucket}",
          "arn:aws:s3:::${aws_s3_bucket.patch_data[0].bucket}/*"
        ]
      }
    ]
  })
}
