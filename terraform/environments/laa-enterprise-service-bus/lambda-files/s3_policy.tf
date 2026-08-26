resource "aws_s3_bucket_policy" "lambda_files_policy" {
  bucket = aws_s3_bucket.lambda_files.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowAllLambdasInAccountRead",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action = [
          "s3:GetObject"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.lambda_files.bucket}/*"
        ],
        Condition = {
          StringEquals = {
            "aws:PrincipalService" = "lambda.amazonaws.com"
          }
        }
      }
    ]
  })
}
