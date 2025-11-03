#####################################################################################
##################### S3 Bucket policy for Hub2.0 Bucket ############################
#####################################################################################
resource "aws_s3_bucket_policy" "data_cross_account_access" {
  bucket = aws_s3_bucket.data.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowCWALambdaReadWrite"
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
        Sid    = "AllowReadAccessFromDB"
        Effect = "Allow",
        Principal = {
          AWS = [
            "arn:aws:iam::${local.application_data.accounts[local.environment].ccms_account_id}:role/role_stsassume_oracle_base",
            "arn:aws:iam::${local.application_data.accounts[local.environment].maatdb_account_id}:role/rds-hub20-s3-access",
            local.application_data.accounts[local.environment].cclf_rds_role_arn,
            local.application_data.accounts[local.environment].ccr_rds_role_arn
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

#####################################################################################
##################### S3 Bucket policy for Wallet Files Bucket ######################
#####################################################################################
resource "aws_s3_bucket_policy" "wallet_files_access" {
  bucket = aws_s3_bucket.wallet_files.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowCWAandCCMSLambdaRead"
        Effect = "Allow",
        Principal = {
          AWS = [
            aws_iam_role.cwa_extract_lambda_role.arn,
            aws_iam_role.ccms_provider_load_role.arn
          ]
        },
        Action = [
          "s3:GetObject"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.wallet_files.bucket}/*"
        ]
      }
    ]
  })
}

#####################################################################################
##################### S3 Bucket policy for Access Logs Bucket #######################
#####################################################################################
resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.access_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.access_logs.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceArn" = aws_s3_bucket.data.arn
          }
        }
      }
    ]
  })
}