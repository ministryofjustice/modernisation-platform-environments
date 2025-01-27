# AWS S3 Bucket (Call Centre Staging)
resource "aws_s3_bucket" "default" {
  bucket = var.call_centre_staging_aws_s3_bucket
  tags   = var.tags
}

# AWS S3 Bucket Policy (Call Centre Staging)
resource "aws_s3_bucket_policy" "default" {
  bucket = var.call_centre_staging_aws_s3_bucket
  policy = jsonencode({
    Version = var.json_encode_decode_version,
    Statement = [
      {
        Sid    = var.moj_aws_s3_bucket_policy_statement_sid,
        Effect = var.moj_aws_s3_bucket_policy_statement_effect,
        Principal = {
          Service : var.moj_aws_s3_bucket_policy_statement_principal_service
        },
        Action   = var.moj_aws_s3_bucket_policy_statement_action,
        Resource = "arn:aws:s3:::${aws_s3_bucket.default.id}/*"
      },
      {
        Sid    = var.bt_genesys_aws_s3_bucket_policy_statement_sid,
        Effect = var.bt_genesys_aws_s3_bucket_policy_statement_effect,
        Principal = {
          AWS = var.bt_genesys_aws_s3_bucket_policy_statement_principal_aws
        },
        Action   = var.bt_genesys_aws_s3_bucket_policy_statement_action,
        Resource = "arn:aws:s3:::${aws_s3_bucket.default.id}/*"
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
  kms_key_arn     = aws_kms_key.s3.arn
  depends_on = [
    aws_s3_bucket.default,
    aws_s3_bucket_policy.default
  ]
}

# AWS KMS Key (Call Centre Staging)
resource "aws_kms_key" "s3" {
  description = var.aws_kms_key_s3_description
  key_usage   = var.aws_kms_key_s3_key_usage
  policy = jsonencode({
    Version = var.json_encode_decode_version,
    Statement = [
      {
        Sid    = var.aws_kms_key_s3_policy_statement_sid,
        Effect = var.aws_kms_key_s3_policy_statement_effect,
        Principal = {
          Service = var.aws_kms_key_s3_policy_statement_principal_service
        },
        Action   = var.aws_kms_key_s3_policy_statement_action,
        Resource = var.aws_kms_key_s3_policy_statement_resource
      }
    ]
  })
}
