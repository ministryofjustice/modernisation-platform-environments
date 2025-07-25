#######################################################################################################
# S3 Buckets, acls, versioning, lifestyle configs, logging, notifications, public access & IAM policies
#######################################################################################################

#######################################################################################################
# Production Environment 
#######################################################################################################

# S3 Bucket for Files copying between the CAFM Environments

resource "aws_s3_bucket" "CAFM" {
  # checkov:skip=CKV_AWS_144: "S3 bucket has cross-region not required"
  bucket = "property-datahub-landing-${local.environment}"

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-CAFM-S3"
    }
  )
}


resource "aws_s3_bucket_versioning" "CAFM" {
  bucket = aws_s3_bucket.CAFM.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "CAFM" {
  # checkov:skip=CKV_AWS_300: "S3 bucket has a set period for aborting failed uploads, this is a false positive finding"
  bucket = aws_s3_bucket.CAFM.id
  rule {
    id     = "tf-s3-lifecycle"
    status = "Enabled"
    filter {
      prefix = "uploads/"
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
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

resource "aws_s3_bucket_logging" "CAFM" {
  bucket        = aws_s3_bucket.CAFM.id
  target_bucket = aws_s3_bucket.LOG.id
  target_prefix = "s3-logs/cafm-files-production-logs/"
}


# S3 block public access
resource "aws_s3_bucket_public_access_block" "CAFM" {
  bucket = aws_s3_bucket.CAFM.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket policy
resource "aws_s3_bucket_policy" "CAFM" {
  bucket = aws_s3_bucket.CAFM.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "RequireSSLRequests",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          aws_s3_bucket.CAFM.arn,
          "${aws_s3_bucket.CAFM.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-development"]}:role/developer",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-development"]}:role/sandbox",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-preproduction"]}:role/developer",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-preproduction"]}:role/migration",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-production"]}:role/developer",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-production"]}:role/migration"
          ]
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.CAFM.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "CAFM" {
  bucket = aws_s3_bucket.CAFM.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.sns_kms.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_sns_topic" "s3_event_topic" {
  name              = "cafm-landing-s3-event-topic"
  kms_master_key_id = aws_kms_key.sns_kms.arn
}

resource "aws_s3_bucket_notification" "bucket_notify" {
  bucket = aws_s3_bucket.CAFM.id

  dynamic "topic" {
    for_each = [
      {
        topic_arn     = aws_sns_topic.s3_event_topic.arn
        events        = ["s3:ObjectCreated:*"]
        filter_prefix = "uploads/planetfm/"
        filter_suffix = ".bak"
      },
      {
        topic_arn     = aws_sns_topic.s3_event_topic.arn
        events        = ["s3:ObjectCreated:*"]
        filter_prefix = "uploads/concept/"
        filter_suffix = ".csv"
      }
    ]

    content {
      topic_arn     = topic.value.topic_arn
      events        = topic.value.events
      filter_prefix = topic.value.filter_prefix
      filter_suffix = topic.value.filter_suffix
    }
  }
}


resource "aws_sns_topic_policy" "s3_publish_policy" {
  arn = aws_sns_topic.s3_event_topic.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "s3.amazonaws.com" },
      Action    = "SNS:Publish",
      Resource  = aws_sns_topic.s3_event_topic.arn,
      Condition = {
        ArnLike = {
          "aws:SourceArn" = aws_s3_bucket.CAFM.arn
        }
      }
    }]
  })
}

#tfsec:ignore:AVD-AWS-0132
#tfsec:ignore:AVD-AWS-0088
resource "aws_s3_bucket" "LOG" {
  # checkov:skip=CKV_AWS_144: "S3 bucket has cross-region not required"
  # checkov:skip=CKV_AWS_145: "S3 bucket encryption not required"
  # checkov:skip=CKV2_AWS_61: "S3 bucket lifecycle policy not required"
  # checkov:skip=CKV2_AWS_62: "S3 bucket event notifications not required"
  bucket = "property-datahub-logs-${local.environment}"

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-LOGS-S3"
    }
  )
}

resource "aws_s3_bucket_versioning" "LOG" {
  bucket = aws_s3_bucket.LOG.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 block public access
resource "aws_s3_bucket_public_access_block" "LOG" {
  bucket = aws_s3_bucket.LOG.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket policy
resource "aws_s3_bucket_policy" "LOG" {
  bucket = aws_s3_bucket.LOG.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Sid" : "RequireSSLRequests",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          aws_s3_bucket.LOG.arn,
          "${aws_s3_bucket.LOG.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-development"]}:role/developer",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-development"]}:role/sandbox",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-preproduction"]}:role/developer",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-preproduction"]}:role/migration",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-production"]}:role/developer",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-production"]}:role/migration"
          ]
        }
        Action = [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.LOG.arn
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-development"]}:role/developer",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-development"]}:role/sandbox",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-preproduction"]}:role/developer",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-preproduction"]}:role/migration",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-production"]}:role/developer",
            "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-production"]}:role/migration"
          ]
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.LOG.arn}/*"
      }
    ]
  })
}
