#######################################################################################################
# S3 Buckets, acls, versioning, lifestyle configs, logging, notifications, public access & IAM policies
#######################################################################################################

#######################################################################################################
# Production Environment 
#######################################################################################################

# S3 Bucket for Files copying between the PPUD Environments

resource "aws_s3_bucket" "PPUD" {
  # checkov:skip=CKV_AWS_145: "S3 bucket is not public facing, does not contain any sensitive information and does not need encryption"
  # checkov:skip=CKV_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV2_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV_AWS_144: "PPUD has a UK Sovereignty requirement so cross region replication is prohibited"
  # checkov:skip=CKV_AWS_18: "S3 bucket logging is not required"
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

resource "aws_s3_bucket_versioning" "PPUD" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.PPUD[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "PPUD" {
  # checkov:skip=CKV_AWS_300: "S3 bucket has a set period for aborting failed uploads, this is a false positive finding"
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.PPUD[0].id
  rule {
    id     = "tf-s3-lifecycle"
    status = "Enabled"
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

resource "aws_s3_bucket_logging" "PPUD" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.PPUD[0].id

  target_bucket = aws_s3_bucket.moj-log-files-prod[0].id
  target_prefix = "s3-logs/ppud-ppud-files-production-logs/"
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

# S3 Bucket for Patch Manager / SSM Health Check Reports

#tfsec:ignore:AWS0088 "S3 bucket is not public facing, does not contain any sensitive information and does not need encryption."
#tfsec:ignore:AVD-AWS-0088
#tfsec:ignore:AVD-AWS-0132
resource "aws_s3_bucket" "MoJ-Health-Check-Reports" {
  # checkov:skip=CKV_AWS_145: "S3 bucket is not public facing, does not contain any sensitive information and does not need encryption"
  # checkov:skip=CKV_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV2_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV_AWS_144: "PPUD has a UK Sovereignty requirement so cross region replication is prohibited"
  # checkov:skip=CKV_AWS_18: "S3 bucket logging is not required"
  bucket = local.application_data.accounts[local.environment].ssm_health_check_reports_s3
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-moj-health-check-reports"
    }
  )
}

resource "aws_s3_bucket_versioning" "MoJ-Health-Check-Reports" {
  bucket = aws_s3_bucket.MoJ-Health-Check-Reports.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "MoJ-Health-Check-Reports" {
  # checkov:skip=CKV_AWS_300: "S3 bucket has a set period for aborting failed uploads, this is a false positive finding"
  bucket = aws_s3_bucket.MoJ-Health-Check-Reports.id
  rule {
    id     = "Remove-Old-SSM-Health-Check-Reports"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    filter {
      prefix = "ssm_output/"
    }
    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "STANDARD_IA"
    }
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
    expiration {
      days = 183
    }
  }
}

resource "aws_s3_bucket_public_access_block" "MoJ-Health-Check-Reports" {
  bucket                  = aws_s3_bucket.MoJ-Health-Check-Reports.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket for PPUD Infrastructure

resource "aws_s3_bucket" "moj-infrastructure" {
  # checkov:skip=CKV_AWS_145: "S3 bucket is not public facing, does not contain any sensitive information and does not need encryption"
  # checkov:skip=CKV_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV2_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV_AWS_144: "PPUD has a UK Sovereignty requirement so cross region replication is prohibited"
  # checkov:skip=CKV_AWS_18: "S3 bucket logging is not required"
  count  = local.is-production == true ? 1 : 0
  bucket = "moj-infrastructure"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-moj-infrastructure"
    }
  )
}

resource "aws_s3_bucket_versioning" "moj-infrastructure" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.moj-infrastructure[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "moj-infrastructure" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.moj-infrastructure[0].id

  target_bucket = aws_s3_bucket.moj-log-files-prod[0].id
  target_prefix = "s3-logs/moj-infrastructure-logs/"
}

resource "aws_s3_bucket_public_access_block" "moj-infrastructure" {
  count                   = local.is-production == true ? 1 : 0
  bucket                  = aws_s3_bucket.moj-infrastructure[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "moj-infrastructure" {
  # checkov:skip=CKV_AWS_300: "S3 bucket has a set period for aborting failed uploads, this is a false positive finding"
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.moj-infrastructure[0].id
  rule {
    id     = "remove-old-moj-infrastructure"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    noncurrent_version_transition {
      noncurrent_days = 183
      storage_class   = "STANDARD_IA"
    }
    transition {
      days          = 183
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_policy" "moj-infrastructure" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.moj-infrastructure[0].id

  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-infrastructure",
          "arn:aws:s3:::moj-infrastructure/*"
        ],
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${local.environment_management.account_ids["ppud-production"]}:role/ec2-iam-role",
            "arn:aws:iam::${local.environment_management.account_ids["ppud-development"]}:role/ec2-iam-role",
            "arn:aws:iam::${local.environment_management.account_ids["ppud-preproduction"]}:role/ec2-iam-role"
          ]
        }
      },
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-infrastructure",
          "arn:aws:s3:::moj-infrastructure/*"
        ],
        "Principal" : {
          Service = "logging.s3.amazonaws.com"
        }
      },
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-infrastructure",
          "arn:aws:s3:::moj-infrastructure/*"
        ],
        "Principal" : {
          Service = "sns.amazonaws.com"
        }
      }
    ]
  })
}

# S3 Bucket for PPUD Database Replication to MoJ Cloud Platform

resource "aws_s3_bucket" "moj-database-source-prod" {
  # checkov:skip=CKV_AWS_145: "S3 bucket is not public facing, does not contain any sensitive information and does not need encryption"
  # checkov:skip=CKV_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV2_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV_AWS_144: "PPUD has a UK Sovereignty requirement so cross region replication is prohibited"
  # checkov:skip=CKV_AWS_18: "S3 bucket logging is not required"
  count  = local.is-production == true ? 1 : 0
  bucket = "moj-database-source-prod"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-moj-database-source-prod"
    }
  )
}

resource "aws_s3_bucket_versioning" "moj-database-source-prod" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.moj-database-source-prod[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "moj-database-source-prod" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.moj-database-source-prod[0].id
  target_bucket = aws_s3_bucket.moj-log-files-prod[0].id
  target_prefix = "s3-logs/moj-database-source-prod-logs/"
}

resource "aws_s3_bucket_public_access_block" "moj-database-source-prod" {
  count                   = local.is-production == true ? 1 : 0
  bucket                  = aws_s3_bucket.moj-database-source-prod[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "moj-database-source-prod" {
  # checkov:skip=CKV_AWS_300: "S3 bucket has a set period for aborting failed uploads, this is a false positive finding"
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.moj-database-source-prod[0].id
  rule {
    id     = "delete-moj-database-source-prod"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 3
    }
    expiration {
      days = 6
    }
  }
}

resource "aws_s3_bucket_policy" "moj-database-source-prod" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.moj-database-source-prod[0].id

  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.moj-database-source-prod[0].arn,
          "${aws_s3_bucket.moj-database-source-prod[0].arn}/*"
        ],
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${local.environment_management.account_ids["ppud-production"]}:role/ec2-iam-role"
          ]
        }
      },
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.moj-database-source-prod[0].arn,
          "${aws_s3_bucket.moj-database-source-prod[0].arn}/*"
        ],
        "Principal" : {
          Service = "logging.s3.amazonaws.com"
        }
      },
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.moj-database-source-prod[0].arn,
          "${aws_s3_bucket.moj-database-source-prod[0].arn}/*"
        ],
        "Principal" : {
          Service = "sns.amazonaws.com"
        }
      }
    ]
  })
}

# S3 Bucket for PPUD MPC Report Replication to MoJ Cloud Platform

resource "aws_s3_bucket" "moj-report-source-prod" {
  # checkov:skip=CKV_AWS_145: "S3 bucket is not public facing, does not contain any sensitive information and does not need encryption"
  # checkov:skip=CKV_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV2_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV_AWS_144: "PPUD has a UK Sovereignty requirement so cross region replication is prohibited"
  # checkov:skip=CKV_AWS_18: "S3 bucket logging is not required"
  count  = local.is-production == true ? 1 : 0
  bucket = "moj-report-source-prod"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-moj-report-source-prod"
    }
  )
}

resource "aws_s3_bucket_versioning" "moj-report-source-prod" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.moj-report-source-prod[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "moj-report-source-prod" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.moj-report-source-prod[0].id
  target_bucket = aws_s3_bucket.moj-log-files-prod[0].id
  target_prefix = "s3-logs/moj-report-source-prod-logs/"
}

resource "aws_s3_bucket_public_access_block" "moj-report-source-prod" {
  count                   = local.is-production == true ? 1 : 0
  bucket                  = aws_s3_bucket.moj-report-source-prod[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "moj-report-source-prod" {
  # checkov:skip=CKV_AWS_300: "S3 bucket has a set period for aborting failed uploads, this is a false positive finding"
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.moj-report-source-prod[0].id
  rule {
    id     = "delete-moj-report-source-prod"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 3
    }
    expiration {
      days = 6
    }
  }
}

resource "aws_s3_bucket_policy" "moj-report-source-prod" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.moj-report-source-prod[0].id

  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.moj-report-source-prod[0].arn,
          "${aws_s3_bucket.moj-report-source-prod[0].arn}/*"
        ],
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${local.environment_management.account_ids["ppud-production"]}:role/ec2-iam-role"
          ]
        }
      },
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.moj-report-source-prod[0].arn,
          "${aws_s3_bucket.moj-report-source-prod[0].arn}/*"
        ],
        "Principal" : {
          Service = "logging.s3.amazonaws.com"
        }
      },
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.moj-report-source-prod[0].arn,
          "${aws_s3_bucket.moj-report-source-prod[0].arn}/*"
        ],
        "Principal" : {
          Service = "sns.amazonaws.com"
        }
      }
    ]
  })
}

# S3 Bucket for S3 Notification and ELB Log Files for Production

resource "aws_s3_bucket" "moj-log-files-prod" {
  # checkov:skip=CKV_AWS_145: "S3 bucket is not public facing, does not contain any sensitive information and does not need encryption"
  # checkov:skip=CKV_AWS_144: "PPUD has a UK Sovereignty requirement so cross region replication is prohibited"
  # checkov:skip=CKV_AWS_18: "S3 bucket logging is not required"
  # checkov:skip=CKV2_AWS_62: "S3 bucket event notification is not required"
  count  = local.is-production == true ? 1 : 0
  bucket = "moj-log-files-prod"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-moj-log-files-prod"
    }
  )
}

resource "aws_s3_bucket_versioning" "moj-log-files-prod" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.moj-log-files-prod[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "moj-log-files-prod" {
  count         = local.is-production == true ? 1 : 0
  bucket        = aws_s3_bucket.moj-log-files-prod[0].id
  target_bucket = aws_s3_bucket.moj-log-files-prod[0].id
  target_prefix = "s3-logs/moj-log-files-prod-logs/"
}

resource "aws_s3_bucket_public_access_block" "moj-log-files-prod" {
  count                   = local.is-production == true ? 1 : 0
  bucket                  = aws_s3_bucket.moj-log-files-prod[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket notification is turned off as it isn't required. It can be re-enabled in future if required.

/*
resource "aws_s3_bucket_notification" "moj-log-files-prod" {
  count  = local.is-production == true ? 1 : 0 
  bucket = aws_s3_bucket.moj-log-files-prod[0].id

  topic {
    topic_arn = aws_sns_topic.s3_bucket_notifications_prod[0].arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "alb-logs/"
  }
}
*/

resource "aws_s3_bucket_lifecycle_configuration" "moj-log-files-prod" {
  # checkov:skip=CKV_AWS_300: "S3 bucket has a set period for aborting failed uploads, this is a false positive finding"
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.moj-log-files-prod[0].id
  rule {
    id     = "Move-to-IA-then-delete-moj-log-files-prod"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    expiration {
      days = 120
    }
  }
}

resource "aws_s3_bucket_policy" "moj-log-files-prod" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.moj-log-files-prod[0].id

  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-log-files-prod",
          "arn:aws:s3:::moj-log-files-prod/*"
        ],
        "Principal" : {
          Service = "logging.s3.amazonaws.com"
        }
      },
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-log-files-prod",
          "arn:aws:s3:::moj-log-files-prod/*"
        ],
        "Principal" : {
          Service = "sns.amazonaws.com"
        }
      },
      {
        "Action" : [
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-log-files-prod",
          "arn:aws:s3:::moj-log-files-prod/*"
        ],
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${local.environment_management.account_ids["ppud-production"]}:role/ec2-iam-role"
          ]
        }
      },
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:ListBucket",
          "s3:PutObject"
        ],
        "Effect" = "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-log-files-prod",
          "arn:aws:s3:::moj-log-files-prod/*"
        ]
        "Principal" : {
          Service = "delivery.logs.amazonaws.com"
        }
      },
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" = "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-log-files-prod",
          "arn:aws:s3:::moj-log-files-prod/*"
        ]
        "Principal" : {
          Service = "elasticloadbalancing.amazonaws.com"
        }
      }
    ]
  })
}

#######################################################################################################
# Preproduction Environment 
#######################################################################################################

# S3 Bucket for S3 Notification and ELB Log Files for Preproduction

resource "aws_s3_bucket" "moj-log-files-uat" {
  # checkov:skip=CKV_AWS_145: "S3 bucket is not public facing, does not contain any sensitive information and does not need encryption"
  # checkov:skip=CKV_AWS_144: "PPUD has a UK Sovereignty requirement so cross region replication is prohibited"
  # checkov:skip=CKV_AWS_18: "S3 bucket logging is not required"
  # checkov:skip=CKV2_AWS_62: "S3 bucket event notification is not required"
  count  = local.is-preproduction == true ? 1 : 0
  bucket = "moj-log-files-uat"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-moj-log-files-uat"
    }
  )
}

resource "aws_s3_bucket_versioning" "moj-log-files-uat" {
  count  = local.is-preproduction == true ? 1 : 0
  bucket = aws_s3_bucket.moj-log-files-uat[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "moj-log-files-uat" {
  count                   = local.is-preproduction == true ? 1 : 0
  bucket                  = aws_s3_bucket.moj-log-files-uat[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket notification is turned off as it isn't required. It can be re-enabled in future if required.

/*
resource "aws_s3_bucket_notification" "moj-log-files-uat" {
  count  = local.is-preproduction == true ? 1 : 0 
  bucket = aws_s3_bucket.moj-log-files-uat[0].id
  topic {
    topic_arn = aws_sns_topic.s3_bucket_notifications_uat[0].arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "alb-logs/"
  }
}
*/

resource "aws_s3_bucket_lifecycle_configuration" "moj-log-files-uat" {
  # checkov:skip=CKV_AWS_300: "S3 bucket has a set period for aborting failed uploads, this is a false positive finding"
  count  = local.is-preproduction == true ? 1 : 0
  bucket = aws_s3_bucket.moj-log-files-uat[0].id
  rule {
    id     = "Move-to-IA-then-delete-moj-log-files-uat"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    expiration {
      days = 60
    }
  }
}

resource "aws_s3_bucket_policy" "moj-log-files-uat" {
  count  = local.is-preproduction == true ? 1 : 0
  bucket = aws_s3_bucket.moj-log-files-uat[0].id

  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-log-files-uat",
          "arn:aws:s3:::moj-log-files-uat/*"
        ],
        "Principal" : {
          Service = "logging.s3.amazonaws.com"
        }
      },
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-log-files-uat",
          "arn:aws:s3:::moj-log-files-uat/*"
        ],
        "Principal" : {
          Service = "sns.amazonaws.com"
        }
      },
      {
        "Action" : [
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-log-files-uat",
          "arn:aws:s3:::moj-log-files-uat/*"
        ],
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${local.environment_management.account_ids["ppud-preproduction"]}:role/ec2-iam-role"
          ]
        }
      },
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:ListBucket",
          "s3:PutObject"
        ],
        "Effect" = "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-log-files-uat",
          "arn:aws:s3:::moj-log-files-uat/*"
        ]
        "Principal" : {
          Service = "delivery.logs.amazonaws.com"
        }
      },
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" = "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-log-files-uat",
          "arn:aws:s3:::moj-log-files-uat/*"
        ]
        "Principal" : {
          Service = "elasticloadbalancing.amazonaws.com"
        }
      }
    ]
  })
}


# S3 Bucket for Report Replication to MPC Service for Preproduction

resource "aws_s3_bucket" "moj-report-source-uat" {
  # checkov:skip=CKV_AWS_145: "S3 bucket is not public facing, does not contain any sensitive information and does not need encryption"
  # checkov:skip=CKV_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV2_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV_AWS_144: "PPUD has a UK Sovereignty requirement so cross region replication is prohibited"
  count  = local.is-preproduction == true ? 1 : 0
  bucket = "moj-report-source-uat"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-moj-report-source-uat"
    }
  )
}

resource "aws_s3_bucket_versioning" "moj-report-source-uat" {
  count  = local.is-preproduction == true ? 1 : 0
  bucket = aws_s3_bucket.moj-report-source-uat[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "moj-report-source-uat" {
  count  = local.is-preproduction == true ? 1 : 0
  bucket        = aws_s3_bucket.moj-report-source-uat[0].id
  target_bucket = aws_s3_bucket.moj-log-files-uat[0].id
  target_prefix = "s3-logs/moj-report-source-uat-logs/"
}

resource "aws_s3_bucket_public_access_block" "moj-report-source-uat" {
  count  = local.is-preproduction == true ? 1 : 0
  bucket                  = aws_s3_bucket.moj-report-source-uat[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "moj-report-source-uat" {
  # checkov:skip=CKV_AWS_300: "S3 bucket has a set period for aborting failed uploads, this is a false positive finding"
  count  = local.is-preproduction == true ? 1 : 0
  bucket = aws_s3_bucket.moj-report-source-uat[0].id
  rule {
    id     = "delete-moj-report-source-uat"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 3
    }
    expiration {
      days = 6
    }
  }
}


resource "aws_s3_bucket_replication_configuration" "moj-report-source-uat-replication" {
  count  = local.is-preproduction == true ? 1 : 0
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.moj-report-source-uat]
  role       = aws_iam_role.iam_role_s3_bucket_moj_report_source_uat[0].arn
  bucket     = aws_s3_bucket.moj-report-source-uat[0].id

  rule {
    id     = "ppud-report-replication-rule-uat"
    status = "Enabled"
    destination {
      bucket        = "arn:aws:s3:::cloud-platform-ffbd9073e2d0d537d825ebea31b441fc"
      storage_class = "STANDARD"
    }
  }
}

resource "aws_s3_bucket_policy" "moj-report-source-uat" {
  count  = local.is-preproduction == true ? 1 : 0
  bucket = aws_s3_bucket.moj-report-source-uat[0].id

  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.moj-report-source-uat[0].arn,
          "${aws_s3_bucket.moj-report-source-uat[0].arn}/*"
        ],
        "Principal" : {
          Service = "logging.s3.amazonaws.com"
        }
      },
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.moj-report-source-uat[0].arn,
          "${aws_s3_bucket.moj-report-source-uat[0].arn}/*"
        ],
        "Principal" : {
          Service = "sns.amazonaws.com"
        }
      },

      {
        "Action" : [
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.moj-report-source-uat[0].arn,
          "${aws_s3_bucket.moj-report-source-uat[0].arn}/*"
        ],
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${local.environment_management.account_ids["ppud-preproduction"]}:role/ec2-iam-role"
          ]
        }
      }
    ]
  })
}

#######################################################################################################
# Development Environment 
#######################################################################################################

# S3 Bucket for S3 Notification and ELB Log Files for Development

resource "aws_s3_bucket" "moj-log-files-dev" {
  # checkov:skip=CKV_AWS_145: "S3 bucket is not public facing, does not contain any sensitive information and does not need encryption"
  # checkov:skip=CKV_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV2_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV_AWS_144: "PPUD has a UK Sovereignty requirement so cross region replication is prohibited"
  # checkov:skip=CKV_AWS_18: "S3 bucket logging is not required"
  count  = local.is-development == true ? 1 : 0
  bucket = "moj-log-files-dev"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-moj-log-files-dev"
    }
  )
}

resource "aws_s3_bucket_versioning" "moj-log-files-dev" {
  count  = local.is-development == true ? 1 : 0
  bucket = aws_s3_bucket.moj-log-files-dev[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "moj-log-files-dev" {
  count                   = local.is-development == true ? 1 : 0
  bucket                  = aws_s3_bucket.moj-log-files-dev[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket notification is turned off as it isn't required. It can be re-enabled in future if required.

/*
resource "aws_s3_bucket_notification" "moj-log-files-dev" {
  count  = local.is-development == true ? 1 : 0 
  bucket = aws_s3_bucket.moj-log-files-dev[0].id
  topic {
    topic_arn = aws_sns_topic.s3_bucket_notifications_dev[0].arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "alb-logs/"
  }
}
*/

resource "aws_s3_bucket_lifecycle_configuration" "moj-log-files-dev" {
  # checkov:skip=CKV_AWS_300: "S3 bucket has a set period for aborting failed uploads, this is a false positive finding"
  count  = local.is-development == true ? 1 : 0
  bucket = aws_s3_bucket.moj-log-files-dev[0].id
  rule {
    id     = "Move-to-IA-then-delete-moj-log-files-dev"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    expiration {
      days = 60
    }
  }
}

resource "aws_s3_bucket_policy" "moj-log-files-dev" {
  count  = local.is-development == true ? 1 : 0
  bucket = aws_s3_bucket.moj-log-files-dev[0].id

  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-log-files-dev",
          "arn:aws:s3:::moj-log-files-dev/*"
        ],
        "Principal" : {
          Service = "logging.s3.amazonaws.com"
        }
      },
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-log-files-dev",
          "arn:aws:s3:::moj-log-files-dev/*"
        ],
        "Principal" : {
          Service = "sns.amazonaws.com"
        }
      },
      {
        "Action" : [
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-log-files-dev",
          "arn:aws:s3:::moj-log-files-dev/*"
        ],
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${local.environment_management.account_ids["ppud-development"]}:role/ec2-iam-role"
          ]
        }
      },
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:ListBucket",
          "s3:PutObject"
        ],
        "Effect" = "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-log-files-dev",
          "arn:aws:s3:::moj-log-files-dev/*"
        ]
        "Principal" : {
          Service = "delivery.logs.amazonaws.com"
        }
      },
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" = "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-log-files-dev",
          "arn:aws:s3:::moj-log-files-dev/*"
        ]
        "Principal" : {
          "AWS" : "arn:aws:iam::652711504416:root" # This ID is the elb-account-id for eu-west-2 obtained from https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
        }
      }
    ]
  })
}

# S3 Bucket for Lambda Layers for Development

resource "aws_s3_bucket" "moj-lambda-layers-dev" {
  # checkov:skip=CKV_AWS_145: "S3 bucket is not public facing, does not contain any sensitive information and does not need encryption"
  # checkov:skip=CKV_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV2_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV_AWS_144: "PPUD has a UK Sovereignty requirement so cross region replication is prohibited"
  # checkov:skip=CKV_AWS_18: "S3 bucket logging is not required"
  count  = local.is-development == true ? 1 : 0
  bucket = "moj-lambda-layers-dev"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-moj-lambda-layers-dev"
    }
  )
}

resource "aws_s3_bucket_versioning" "moj-lambda-layers-dev" {
  count  = local.is-development == true ? 1 : 0
  bucket = aws_s3_bucket.moj-lambda-layers-dev[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "moj-lambda-layers-dev" {
  count                   = local.is-development == true ? 1 : 0
  bucket                  = aws_s3_bucket.moj-lambda-layers-dev[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "moj-lambda-layers-dev" {
  # checkov:skip=CKV_AWS_300: "S3 bucket has a set period for aborting failed uploads, this is a false positive finding"
  count  = local.is-development == true ? 1 : 0
  bucket = aws_s3_bucket.moj-lambda-layers-dev[0].id
  rule {
    id     = "Move-to-IA-then-delete-moj-lambda-layers-dev"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    expiration {
      days = 60
    }
  }
}

resource "aws_s3_bucket_policy" "moj-lambda-layers-dev" {
  count  = local.is-development == true ? 1 : 0
  bucket = aws_s3_bucket.moj-lambda-layers-dev[0].id

  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-lambda-layers-dev",
          "arn:aws:s3:::moj-lambda-layers-dev/*"
        ],
        "Principal" : {
          Service = "logging.s3.amazonaws.com"
        }
      },
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-lambda-layers-dev",
          "arn:aws:s3:::moj-lambda-layers-dev/*"
        ],
        "Principal" : {
          Service = "sns.amazonaws.com"
        }
      },
      {
        "Action" : [
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-lambda-layers-dev",
          "arn:aws:s3:::moj-lambda-layers-dev/*"
        ],
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${local.environment_management.account_ids["ppud-development"]}:role/ec2-iam-role"
          ]
        }
      }
    ]
  })
}

# S3 Bucket for Database Replication to Cloud Platform Team for Development

resource "aws_s3_bucket" "moj-database-source-dev" {
  # checkov:skip=CKV_AWS_145: "S3 bucket is not public facing, does not contain any sensitive information and does not need encryption"
  # checkov:skip=CKV_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV2_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV_AWS_144: "PPUD has a UK Sovereignty requirement so cross region replication is prohibited"
  count  = local.is-development == true ? 1 : 0
  bucket = "moj-database-source-dev"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-moj-database-source-dev"
    }
  )
}

resource "aws_s3_bucket_versioning" "moj-database-source-dev" {
  count  = local.is-development == true ? 1 : 0
  bucket = aws_s3_bucket.moj-database-source-dev[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "moj-database-source-dev" {
  count         = local.is-development == true ? 1 : 0
  bucket        = aws_s3_bucket.moj-database-source-dev[0].id
  target_bucket = aws_s3_bucket.moj-log-files-dev[0].id
  target_prefix = "s3-logs/moj-database-source-dev-logs/"
}

resource "aws_s3_bucket_public_access_block" "moj-database-source-dev" {
  count                   = local.is-development == true ? 1 : 0
  bucket                  = aws_s3_bucket.moj-database-source-dev[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "moj-database-source-dev" {
  # checkov:skip=CKV_AWS_300: "S3 bucket has a set period for aborting failed uploads, this is a false positive finding"
  count  = local.is-development == true ? 1 : 0
  bucket = aws_s3_bucket.moj-database-source-dev[0].id
  rule {
    id     = "delete-moj-database-source-dev"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 3
    }
    expiration {
      days = 6
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "moj-database-source-dev-replication" {
  count = local.is-development == true ? 1 : 0
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.moj-database-source-dev]
  role       = aws_iam_role.iam_role_s3_bucket_moj_database_source_dev[0].arn
  bucket     = aws_s3_bucket.moj-database-source-dev[0].id

  rule {
    id     = "ppud-database-replication-rule-dev"
    status = "Enabled"
    destination {
      bucket        = "arn:aws:s3:::mojap-data-engineering-production-ppud-dev"
      storage_class = "STANDARD"
    }
  }
}

resource "aws_s3_bucket_policy" "moj-database-source-dev" {
  count  = local.is-development == true ? 1 : 0
  bucket = aws_s3_bucket.moj-database-source-dev[0].id

  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.moj-database-source-dev[0].arn,
          "${aws_s3_bucket.moj-database-source-dev[0].arn}/*"
        ],
        "Principal" : {
          Service = "logging.s3.amazonaws.com"
        }
      },
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.moj-database-source-dev[0].arn,
          "${aws_s3_bucket.moj-database-source-dev[0].arn}/*"
        ],
        "Principal" : {
          Service = "sns.amazonaws.com"
        }
      },

      {
        "Action" : [
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.moj-database-source-dev[0].arn,
          "${aws_s3_bucket.moj-database-source-dev[0].arn}/*"
        ],
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${local.environment_management.account_ids["ppud-development"]}:role/ec2-iam-role"
          ]
        }
      }
    ]
  })
}

# S3 Bucket for Report Replication to MPC Service for Development

resource "aws_s3_bucket" "moj-report-source-dev" {
  # checkov:skip=CKV_AWS_145: "S3 bucket is not public facing, does not contain any sensitive information and does not need encryption"
  # checkov:skip=CKV_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV2_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV_AWS_144: "PPUD has a UK Sovereignty requirement so cross region replication is prohibited"
  count  = local.is-development == true ? 1 : 0
  bucket = "moj-report-source-dev"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-moj-report-source-dev"
    }
  )
}

resource "aws_s3_bucket_versioning" "moj-report-source-dev" {
  count  = local.is-development == true ? 1 : 0
  bucket = aws_s3_bucket.moj-report-source-dev[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "moj-report-source-dev" {
  count         = local.is-development == true ? 1 : 0
  bucket        = aws_s3_bucket.moj-report-source-dev[0].id
  target_bucket = aws_s3_bucket.moj-log-files-dev[0].id
  target_prefix = "s3-logs/moj-report-source-dev-logs/"
}

resource "aws_s3_bucket_public_access_block" "moj-report-source-dev" {
  count                   = local.is-development == true ? 1 : 0
  bucket                  = aws_s3_bucket.moj-report-source-dev[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "moj-report-source-dev" {
  # checkov:skip=CKV_AWS_300: "S3 bucket has a set period for aborting failed uploads, this is a false positive finding"
  count  = local.is-development == true ? 1 : 0
  bucket = aws_s3_bucket.moj-report-source-dev[0].id
  rule {
    id     = "delete-moj-report-source-dev"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 3
    }
    expiration {
      days = 6
    }
  }
}


resource "aws_s3_bucket_replication_configuration" "moj-report-source-dev-replication" {
  count = local.is-development == true ? 1 : 0
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.moj-report-source-dev]
  role       = aws_iam_role.iam_role_s3_bucket_moj_report_source_dev[0].arn
  bucket     = aws_s3_bucket.moj-report-source-dev[0].id

  rule {
    id     = "ppud-report-replication-rule-dev"
    status = "Enabled"
    destination {
      bucket        = "arn:aws:s3:::cloud-platform-db973d65892f599f6e78cb90252d7dc9"
      storage_class = "STANDARD"
    }
  }
}

resource "aws_s3_bucket_policy" "moj-report-source-dev" {
  count  = local.is-development == true ? 1 : 0
  bucket = aws_s3_bucket.moj-report-source-dev[0].id

  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.moj-report-source-dev[0].arn,
          "${aws_s3_bucket.moj-report-source-dev[0].arn}/*"
        ],
        "Principal" : {
          Service = "logging.s3.amazonaws.com"
        }
      },
      {
        "Action" : [
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.moj-report-source-dev[0].arn,
          "${aws_s3_bucket.moj-report-source-dev[0].arn}/*"
        ],
        "Principal" : {
          Service = "sns.amazonaws.com"
        }
      },

      {
        "Action" : [
          "s3:GetBucketAcl",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.moj-report-source-dev[0].arn,
          "${aws_s3_bucket.moj-report-source-dev[0].arn}/*"
        ],
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${local.environment_management.account_ids["ppud-development"]}:role/ec2-iam-role"
          ]
        }
      }
    ]
  })
}
