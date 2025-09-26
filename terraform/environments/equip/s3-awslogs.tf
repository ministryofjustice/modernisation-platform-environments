data "aws_elb_service_account" "main" {}

resource "random_string" "bucket_suffix" {
  length  = 6
  special = false
  upper   = false
}

#tfsec:ignore:aws-s3-enable-bucket-encryption tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning tfsec:ignore:aws-s3-block-public-acls  tfsec:ignore:aws-s3-block-public-policy  tfsec:ignore:aws-s3-ignore-public-acls  tfsec:ignore:aws-s3-no-public-buckets  tfsec:ignore:aws-s3-specify-public-access-block
#trivy:ignore:avd-aws-0087 trivy:ignore:avd-aws-0089 trivy:ignore:avd-aws-0090 trivy:ignore:avd-aws-0091 trivy:ignore:avd-aws-0093
resource "aws_s3_bucket" "this" {
  #checkov:skip=CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
  #checkov:skip=CKV2_AWS_62: "S3 bucket event notification is not required"
  #checkov:skip=CKV_AWS_18:"Access logging not required"
  #checkov:skip=CKV_AWS_21: "Ensure all data stored in the S3 bucket have versioning enabled"
  #checkov:skip=CKV_AWS_144:Cross-region replication not required
  bucket_prefix = "moj-alb-citrix-access-logs-bucket"

  tags = {
    Environment = "Development"
    Name        = "S3 Access Logs for ALB"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket-config" {
  # checkov:skip=CKV_AWS_300: "S3 bucket has a set period for aborting failed uploads, this is a false positive finding"
  bucket = aws_s3_bucket.this.bucket

  rule {
    id = "log_deletion"

    expiration {
      days = 90
    }

    filter {
      and {
        prefix = "AWSLogs/${data.aws_caller_identity.current.account_id}/"

        tags = {
          rule      = "log-deletion"
          autoclean = "true"
        }
      }
    }
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
}

#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${data.aws_elb_service_account.main.arn}"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.this.id}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.this.id}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.this.id}"
    },
    {

       "Sid": "S3PolicyStmt",
       "Effect": "Allow",
       "Principal": {
           "Service": "logging.s3.amazonaws.com"
       },
       "Action": "s3:PutObject",
       "Resource": "arn:aws:s3:::${aws_s3_bucket.this.id}/*"
     }
  ]
}
EOF
}
