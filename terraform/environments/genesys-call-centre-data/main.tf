# AWS S3 Bucket (Call Centre Staging)
resource "aws_s3_bucket" "default" {
  bucket = var.call_centre_staging_aws_s3_bucket
  tags   = {
    environment = var.aws_s3_bucket_tags_environment
  }
}

# AWS S3 Bucket Policy (Call Centre Staging)
resource "aws_s3_bucket_policy" "default" {
  bucket     = var.call_centre_staging_aws_s3_bucket
  policy     = jsondecode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowAccountFullAccess",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action    = "s3:*",
        Resource  = [
          "arn:aws:s3:::${aws_s3_bucket.default.id}",
          "arn:aws:s3:::${aws_s3_bucket.default.id}/*"
        ]
      },
      {
        Sid       = "AllowThirdPartyWriteOnly",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${var.bt_genesys_aws_third_party_account_id}:root",
        },
        Action    = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Resource  = "arn:aws:s3:::${aws_s3_bucket.default.id}/*"
      }
    ]
  })
}

# AWS GuardDuty Detector (Call Centre Staging)
resource "aws_guardduty_detector" "default" {
 enable = var.aws_guardduty_detector_enable
}

# AWS GuardDuty Publishing Destination (Call Centre Staging)
resource "aws_guardduty_publishing_destination" "default" {
  detector_id     = aws_guardduty_detector.default.id
  destination_arn = aws_s3_bucket.default.arn
  kms_key_arn     = aws_kms_key.default.arn
  depends_on      = [
    aws_s3_bucket.default,
    aws_s3_bucket_policy.default
  ]
}

# # AWS KMS Key (Call Centre Staging)
# resource "aws_kms_key" "default" {
#   description = ""
#   key_usage   = ""
#   policy      = ""
# }
