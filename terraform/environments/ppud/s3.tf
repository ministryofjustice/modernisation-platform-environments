
#----------------------------------------------------------
# S3 Bucket for Files copying between the PPUD Environments
#----------------------------------------------------------

resource "aws_s3_bucket" "PPUD" {
  count  = local.is-production == true ? 1 : 0
  bucket = "${local.application_name}-ppud-files-${local.environment}"

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-PPUD-S3"
    }
  )
}

resource "aws_s3_bucket_acl" "PPUD_ACL" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.PPUD[0].id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "PPUD" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.PPUD[0].id
  rule {
    id     = "tf-s3-lifecycle"
    status = "Enabled"
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "STANDARD_IA"
    }
  }
}


# S3 block public access
resource "aws_s3_bucket_public_access_block" "PPUD" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.PPUD[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket policy

resource "aws_s3_bucket_policy" "PPUD" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.PPUD[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
          "arn:aws:iam::${local.environment_management.account_ids["ppud-development"]}:role/developer",
          "arn:aws:iam::${local.environment_management.account_ids["ppud-development"]}:role/sandbox",
          "arn:aws:iam::${local.environment_management.account_ids["ppud-preproduction"]}:role/developer",
          "arn:aws:iam::${local.environment_management.account_ids["ppud-preproduction"]}:role/migration",
          "arn:aws:iam::${local.environment_management.account_ids["ppud-production"]}:role/developer",
          "arn:aws:iam::${local.environment_management.account_ids["ppud-production"]}:role/migration"
          ]
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.PPUD[0].arn}/*"
      }
    ]
  })
}
