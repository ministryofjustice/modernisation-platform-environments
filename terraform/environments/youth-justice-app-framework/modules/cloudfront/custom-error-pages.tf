data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "error_page" {
  #checkov:skip=CKV2_AWS_62:"Event notifications not required for CloudFront error pages
  #checkov:skip=CKV2_AWS_61:"Dont want to delete any files in this bucket"
  #checkov:skip=CKV_AWS_144:"Do not need to replicate error pages as stored in terraform anyway"
  #checkov:skip=CKV_AWS_18:"Logging not required for error pages"
  bucket        = "yjaf-${var.environment}-custom-error-pages"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "error_page" {
  bucket = aws_s3_bucket.error_page.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.cloudfront_s3.arn
    }
  }
}

resource "aws_s3_bucket_versioning" "error_page" {
  bucket = aws_s3_bucket.error_page.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "error_page_public" {
  bucket = aws_s3_bucket.error_page.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "custom_503" {
  bucket       = aws_s3_bucket.error_page.id
  key          = "custom-503.html"
  source       = "${path.module}/custom-503.html" # Local file
  content_type = "text/html"
  acl          = "private"
}

resource "aws_s3_bucket_policy" "error_page_policy" {
  bucket = aws_s3_bucket.error_page.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement : [
      {
        Sid : "AllowCloudFrontServiceAccessViaOAC",
        Effect : "Allow",
        Principal : {
          Service : "cloudfront.amazonaws.com"
        },
        Action : "s3:GetObject",
        Resource : "${aws_s3_bucket.error_page.arn}/*",
        Condition : {
          StringEquals : {
            "AWS:SourceArn" : "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${var.cloudfront_distribution_id}"
          }
        }
      }
    ]
  })
}

resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "cloudfront-${var.environment}-s3-oac"
  description                       = "OAC for CloudFront to access S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for private S3 access"
}

resource "aws_kms_key" "cloudfront_s3" {
  description             = "KMS key for CloudFront ${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "cloudfront-s3-kms-policy",
    Statement : [
      {
        Sid : "AllowCloudFrontServiceAccess",
        Effect : "Allow",
        Principal : {
          Service : "cloudfront.amazonaws.com"
        },
        Action : [
          "kms:Decrypt",
          "kms:DescribeKey"
        ],
        Resource : "*",
        Condition : {
          StringEquals : {
            "kms:ViaService" : "s3.${data.aws_region.current.name}.amazonaws.com",
            "kms:CallerAccount" : data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid : "AllowRootAccountFullAccess",
        Effect : "Allow",
        Principal : {
          AWS : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action : "kms:*",
        Resource : "*"
      }
    ]
  })
}

resource "aws_kms_alias" "cloudfront_s3" {
  name          = "alias/cloudfront-${var.environment}"
  target_key_id = aws_kms_key.cloudfront_s3.id
}