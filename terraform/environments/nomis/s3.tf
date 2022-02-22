
module "s3-bucket" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v4.0.0"

  providers = {
    aws.bucket-replication = aws
  }
  bucket_prefix       = "s3-bucket"
  replication_enabled = false

  lifecycle_rule = [
    {
      id      = "main"
      enabled = true
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = local.tags
}

resource "aws_s3_bucket_policy" "loadbalancer_logs" {
  bucket = module.s3-bucket.bucket.id
  policy = jsonencode( # policy from: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html#access-logging-bucket-permissions
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "arn:aws:iam::652711504416:root"
          },
          "Action" : "s3:PutObject",
          "Resource" : "${module.s3-bucket.bucket.arn}/loadbalancer-logs/AWSLogs/${local.environment_management.account_ids[terraform.workspace]}/*"
        },
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "delivery.logs.amazonaws.com"
          },
          "Action" : "s3:PutObject",
          "Resource" : "${module.s3-bucket.bucket.arn}/loadbalancer-logs/AWSLogs/${local.environment_management.account_ids[terraform.workspace]}/*",
          "Condition" : {
            "StringEquals" : {
              "s3:x-amz-acl" : "bucket-owner-full-control"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "delivery.logs.amazonaws.com"
          },
          "Action" : "s3:GetBucketAcl",
          "Resource" : "${module.s3-bucket.bucket.arn}"
        }
      ]
    }
  )
}

module "nomis-db-backup-bucket" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v4.0.0"

  providers = {
    aws.bucket-replication = aws
  }
  bucket_prefix       = "nomis-db-backup-bucket"
  replication_enabled = false

  lifecycle_rule = [
    {
      id      = "main"
      enabled = true
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = local.tags

}

