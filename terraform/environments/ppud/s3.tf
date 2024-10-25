#######################################################################################################
# S3 Buckets, acls, versioning, lifestyle configs, logging, notifications, public access & IAM policies
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
  target_prefix = "logs/"
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
      noncurrent_days = 183
      storage_class   = "STANDARD_IA"
    }

    transition {
      days          = 183
      storage_class = "STANDARD_IA"
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

# S3 Bucket for MoJ Powershell and Bash Scripts 

resource "aws_s3_bucket" "moj-scripts" {
  # checkov:skip=CKV_AWS_145: "S3 bucket is not public facing, does not contain any sensitive information and does not need encryption"
  # checkov:skip=CKV_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV2_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV_AWS_144: "PPUD has a UK Sovereignty requirement so cross region replication is prohibited"
  # checkov:skip=CKV_AWS_18: "S3 bucket logging is not required"
  count  = local.is-production == true ? 1 : 0
  bucket = "moj-scripts"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-moj-scripts"
    }
  )
}

resource "aws_s3_bucket_versioning" "moj-scripts" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.moj-scripts[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "moj-scripts" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.moj-scripts[0].id

  target_bucket = aws_s3_bucket.moj-log-files-prod[0].id
  target_prefix = "logs/"
}

resource "aws_s3_bucket_public_access_block" "moj-scripts" {
  count                   = local.is-production == true ? 1 : 0
  bucket                  = aws_s3_bucket.moj-scripts[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "moj-scripts" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.moj-scripts[0].id
  rule {
    id     = "remove-old-moj-scripts"
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

resource "aws_s3_bucket_policy" "moj-scripts" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.moj-scripts[0].id

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
          "arn:aws:s3:::moj-scripts",
          "arn:aws:s3:::moj-scripts/*"
        ],
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${local.environment_management.account_ids["ppud-development"]}:role/ec2-iam-role",
            "arn:aws:iam::${local.environment_management.account_ids["ppud-preproduction"]}:role/ec2-iam-role"
          ]
        }
      }
    ]
  })
}


# S3 Bucket for Release-Management (Application & Software) Files

resource "aws_s3_bucket" "MoJ-Release-Management" {
  # checkov:skip=CKV_AWS_145: "S3 bucket is not public facing, does not contain any sensitive information and does not need encryption"
  # checkov:skip=CKV_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV2_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV_AWS_144: "PPUD has a UK Sovereignty requirement so cross region replication is prohibited"
  # checkov:skip=CKV_AWS_18: "S3 bucket logging is not required"
  count  = local.is-production == true ? 1 : 0
  bucket = "moj-release-management"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-moj-release-management"
    }
  )
}

resource "aws_s3_bucket_versioning" "MoJ-Release-Management" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.MoJ-Release-Management[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "MoJ-Release-Management" {
  # checkov:skip=CKV_AWS_300: "S3 bucket has a set period for aborting failed uploads, this is a false positive finding"
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.MoJ-Release-Management[0].id
  rule {
    id     = "Remove-Old-MoJ-Release-Management"
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
  }
}

resource "aws_s3_bucket_logging" "MoJ-Release-Management" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.MoJ-Release-Management[0].id

  target_bucket = aws_s3_bucket.moj-log-files-prod[0].id
  target_prefix = "logs/"
}

resource "aws_s3_bucket_public_access_block" "MoJ-Release-Management" {
  count                   = local.is-production == true ? 1 : 0
  bucket                  = aws_s3_bucket.MoJ-Release-Management[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_policy" "MoJ-Release-Management" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.MoJ-Release-Management[0].id

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
          "arn:aws:s3:::moj-release-management",
          "arn:aws:s3:::moj-release-management/*"
        ],
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${local.environment_management.account_ids["ppud-development"]}:role/ec2-iam-role",
            "arn:aws:iam::${local.environment_management.account_ids["ppud-preproduction"]}:role/ec2-iam-role"
          ]
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
      days = 60
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

# S3 Bucket for S3 Notification and ELB Log Files for Preproduction

resource "aws_s3_bucket" "moj-log-files-uat" {
  # checkov:skip=CKV_AWS_145: "S3 bucket is not public facing, does not contain any sensitive information and does not need encryption"
  # checkov:skip=CKV_AWS_144: "PPUD has a UK Sovereignty requirement so cross region replication is prohibited"
  # checkov:skip=CKV_AWS_18: "S3 bucket logging is not required"
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
          "AWS": "arn:aws:iam::652711504416:root" # This ID is the elb-account-id for eu-west-2 obtained from https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
        }
      }
    ]
  })
}
