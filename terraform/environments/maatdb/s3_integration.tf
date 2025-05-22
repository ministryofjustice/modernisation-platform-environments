
locals {

  app_name = local.application_data.accounts[local.environment].application_name

}

# FTP Buckets

# Outbound
resource "aws_s3_bucket" "outbound_ftp_bucket" {
  bucket = "maat-outbound-ftp-bucket"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "outbound_ftp_bucket_sse" {
  bucket = aws_s3_bucket.outbound_ftp_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = data.aws_kms_key.general_shared.arn    
      }
  }
}

# Inbound

resource "aws_s3_bucket" "inbound_ftp_bucket" {
  bucket = "maat-inbound-ftp-bucket"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "inbound_ftp_bucket_sse" {
  bucket = aws_s3_bucket.inbound_ftp_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = data.aws_kms_key.general_shared.arn
    }
  }
}



# SES IAM User
resource "aws_iam_user" "ses_user" {
  name = "${local.app_name}-ses-user"
}

# resource "aws_iam_user_policy" "ses_user_policy" {
#   name = "${var.application_name}-SESUserPolicy"
#   user = aws_iam_user.ses_user.name

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect   = "Allow",
#         Action   = ["ses:SendRawEmail"],
#         Resource = "*"
#       }
#     ]
#   })
# }

# FTP IAM User
resource "aws_iam_user" "ftp_user" {
  name = "${local.app_name}-ftp-user"
}

resource "aws_iam_user_policy" "ftp_user_policy" {
  name = "${local.application_name}-FTPUserPolicy"
  user = aws_iam_user.ftp_user.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketPolicy",
          "s3:ListBucket",
          "s3:PutObject"
        ],
        Resource = [
          aws_s3_bucket.outbound_ftp_bucket.arn,
          "${aws_s3_bucket.outbound_ftp_bucket.arn}/*",
          aws_s3_bucket.inbound_ftp_bucket.arn,
          "${aws_s3_bucket.inbound_ftp_bucket.arn}/*"
        ]
      }
    ]
  })
}
