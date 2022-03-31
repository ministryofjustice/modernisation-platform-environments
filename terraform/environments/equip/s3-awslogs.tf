data "aws_elb_service_account" "main" {}

data "aws_caller_identity" "current" {}

#tfsec:ignore:aws-s3-enable-bucket-encryption tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning tfsec:ignore:aws-s3-block-public-acls  tfsec:ignore:aws-s3-block-public-policy  tfsec:ignore:aws-s3-ignore-public-acls  tfsec:ignore:aws-s3-no-public-buckets  tfsec:ignore:aws-s3-specify-public-access-block
resource "aws_s3_bucket" "this" {
  #checkov:skip=CKV_AWS_19
  #checkov:skip=CKV_AWS_18
  #checkov:skip=CKV_AWS_144
  #checkov:skip=CKV_AWS_145
  #checkov:skip=CKV_AWS_21
  #checkov:skip=CKV2_AWS_6
  #checkov:skip=CKV2_AWS_41
  #checkov:skip=CKV2_AWS_37
  bucket = "moj-alb-citrix-access-logs-bucket"

  tags = {
    Environment = "Development"
    Name        = "S3 Access Logs for ALB"
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

       "Sid": "S3PolicyStmt-DO-NOT-MODIFY-1648624790828",
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
