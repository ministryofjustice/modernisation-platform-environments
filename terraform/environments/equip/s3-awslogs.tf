data "aws_elb_service_account" "main" {}

resource "random_string" "bucket_suffix" {
  length  = 6
  special = false
  upper   = false
}

#tfsec:ignore:aws-s3-enable-bucket-encryption tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning tfsec:ignore:aws-s3-block-public-acls  tfsec:ignore:aws-s3-block-public-policy  tfsec:ignore:aws-s3-ignore-public-acls  tfsec:ignore:aws-s3-no-public-buckets  tfsec:ignore:aws-s3-specify-public-access-block
resource "aws_s3_bucket" "this" {
  bucket_prefix = "moj-alb-citrix-access-logs-bucket"

  tags = {
    Environment = "Development"
    Name        = "S3 Access Logs for ALB"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket-config" {
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
