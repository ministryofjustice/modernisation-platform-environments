#######################################################################################################
# S3 Buckets, acls, versioning, lifestyle configs, logging, notifications, public access & IAM policies
#######################################################################################################

#######################################################################################################
# Production Environment 
#######################################################################################################

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
/*
resource "aws_s3_bucket_logging" "moj-log-files-prod" {
  count         = local.is-production == true ? 1 : 0
  bucket        = aws_s3_bucket.moj-log-files-prod[0].id
  target_bucket = aws_s3_bucket.moj-log-files-prod[0].id
  target_prefix = "s3-logs/moj-log-files-prod-logs/"
}
*/
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
    filter {
      prefix = ""
    }
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
        "Sid" : "RequireSSLRequests",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          aws_s3_bucket.moj-log-files-prod[0].arn,
          "${aws_s3_bucket.moj-log-files-prod[0].arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
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
          aws_s3_bucket.moj-log-files-prod[0].arn,
          "${aws_s3_bucket.moj-log-files-prod[0].arn}/*"
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
          aws_s3_bucket.moj-log-files-prod[0].arn,
          "${aws_s3_bucket.moj-log-files-prod[0].arn}/*"
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
          aws_s3_bucket.moj-log-files-prod[0].arn,
          "${aws_s3_bucket.moj-log-files-prod[0].arn}/*"
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
        "Effect" : "Allow",
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
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.moj-log-files-prod[0].arn,
          "${aws_s3_bucket.moj-log-files-prod[0].arn}/*"
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
/*
resource "aws_s3_bucket_logging" "moj-log-files-uat" {
  count         = local.is-preproduction == true ? 1 : 0
  bucket        = aws_s3_bucket.moj-log-files-uat[0].id
  target_bucket = aws_s3_bucket.moj-log-files-uat[0].id
  target_prefix = "s3-logs/moj-log-files-uat-logs/"
}
*/
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
    filter {
      prefix = ""
    }
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

resource "aws_s3_bucket_policy" "moj-log-files-uat" {
  count  = local.is-preproduction == true ? 1 : 0
  bucket = aws_s3_bucket.moj-log-files-uat[0].id

  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "RequireSSLRequests",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          aws_s3_bucket.moj-log-files-uat[0].arn,
          "${aws_s3_bucket.moj-log-files-uat[0].arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
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
          aws_s3_bucket.moj-log-files-uat[0].arn,
          "${aws_s3_bucket.moj-log-files-uat[0].arn}/*"
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
          aws_s3_bucket.moj-log-files-uat[0].arn,
          "${aws_s3_bucket.moj-log-files-uat[0].arn}/*"
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
          aws_s3_bucket.moj-log-files-uat[0].arn,
          "${aws_s3_bucket.moj-log-files-uat[0].arn}/*"
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
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.moj-log-files-uat[0].arn,
          "${aws_s3_bucket.moj-log-files-uat[0].arn}/*"
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
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.moj-log-files-uat[0].arn,
          "${aws_s3_bucket.moj-log-files-uat[0].arn}/*"
        ]
        "Principal" : {
          Service = "elasticloadbalancing.amazonaws.com"
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
/*
resource "aws_s3_bucket_logging" "moj-log-files-dev" {
  count         = local.is-development == true ? 1 : 0
  bucket        = aws_s3_bucket.moj-log-files-dev[0].id
  target_bucket = aws_s3_bucket.moj-log-files-dev[0].id
  target_prefix = "s3-logs/moj-log-files-dev-logs/"
}
*/
resource "aws_s3_bucket_public_access_block" "moj-log-files-dev" {
  count                   = local.is-development == true ? 1 : 0
  bucket                  = aws_s3_bucket.moj-log-files-dev[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "moj-log-files-dev" {
  count  = local.is-development == true ? 1 : 0
  bucket = aws_s3_bucket.moj-log-files-dev[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
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
    filter {
      prefix = ""
    }
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

resource "aws_s3_bucket_policy" "moj-log-files-dev" {
  count  = local.is-development == true ? 1 : 0
  bucket = aws_s3_bucket.moj-log-files-dev[0].id

  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "RequireSSLRequests",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          aws_s3_bucket.moj-log-files-dev[0].arn,
          "${aws_s3_bucket.moj-log-files-dev[0].arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
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
          aws_s3_bucket.moj-log-files-dev[0].arn,
          "${aws_s3_bucket.moj-log-files-dev[0].arn}/*"
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
          aws_s3_bucket.moj-log-files-dev[0].arn,
          "${aws_s3_bucket.moj-log-files-dev[0].arn}/*"
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
          aws_s3_bucket.moj-log-files-dev[0].arn,
          "${aws_s3_bucket.moj-log-files-dev[0].arn}/*"
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
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.moj-log-files-dev[0].arn,
          "${aws_s3_bucket.moj-log-files-dev[0].arn}/*"
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
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.moj-log-files-dev[0].arn,
          "${aws_s3_bucket.moj-log-files-dev[0].arn}/*"
        ]
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${data.aws_ssm_parameter.elb-account-eu-west-2-dev[0].value}:root" # This ID is the elb-account-id for eu-west-2 obtained from https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
          ]
        }
      }
    ]
  })
}

