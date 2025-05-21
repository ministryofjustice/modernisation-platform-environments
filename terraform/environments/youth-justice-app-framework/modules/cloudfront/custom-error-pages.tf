resource "aws_s3_bucket" "error_page" {
  bucket        = "yjaf-${var.environment}-custom-error-pages"
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = var.kms_key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = var.logging_bucket_name
    target_prefix = "s3/${var.environment}/error-page-logs/"
  }

  lifecycle_rule {
    id      = "expire-old-objects"
    enabled = true

    expiration {
      days = 365
    }
  }

  replication_configuration {
    role = var.replication_role_arn

    rules {
      id     = "replicate-everything"
      status = "Enabled"

      filter {}

      destination {
        bucket        = var.replica_bucket_arn
        storage_class = "STANDARD"
      }
    }
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
  source       = "custom-503.html" # Local file
  content_type = "text/html"
  acl          = "private"
}

resource "aws_s3_bucket_policy" "error_page_policy" {
  bucket = aws_s3_bucket.error_page.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        },
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.error_page.arn}/*"
      }
    ]
  })
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for private S3 access"
}