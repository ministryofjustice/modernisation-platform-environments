resource "aws_kms_key" "s3_key" {
  count                   = contains(local.deploy_to, local.environment) ? 1 : 0
  description             = "KMS key for private S3 bucket encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = merge(local.extended_tags, {
    description = "KMS key for tfstate bucket"
  })
}

resource "aws_kms_alias" "s3_key_alias" {
  count         = contains(local.deploy_to, local.environment) ? 1 : 0
  name          = "alias/streaming-poc-s3-tfstate"
  target_key_id = aws_kms_key.s3_key[0].key_id
}

resource "aws_s3_bucket" "tfstate" {
  #checkov:skip=CKV_AWS_18:access logs not required for the bucket
  #checkov:skip=CKV_AWS_144:cross region replication not required
  #checkov:skip=CKV2_AWS_62:events not required

  count         = contains(local.deploy_to, local.environment) ? 1 : 0
  bucket        = "streaming-poc-tfstate"
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "versioning" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  bucket = aws_s3_bucket.tfstate[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  bucket = aws_s3_bucket.tfstate[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key[0].arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# 5. Block All Public Access (Bucket Level)
resource "aws_s3_bucket_public_access_block" "public_block" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  bucket = aws_s3_bucket.tfstate[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "secure_policy" {
  count  = contains(local.deploy_to, local.environment) ? 1 : 0
  bucket = aws_s3_bucket.tfstate[0].id

  depends_on = [aws_s3_bucket_public_access_block.public_block]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLSRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.tfstate[0].arn,
          "${aws_s3_bucket.tfstate[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "AllowAccountOwnerFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.tfstate[0].arn,
          "${aws_s3_bucket.tfstate[0].arn}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "state_lifecycle" {
  depends_on = [aws_s3_bucket_versioning.versioning]
  bucket     = aws_s3_bucket.tfstate[0].id

  #Retain current + 1 version, remove other versions older than 180 months
  rule {
    id     = "retain-current-plus-one-history"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days           = 180
      newer_noncurrent_versions = 1
    }

  }
}
