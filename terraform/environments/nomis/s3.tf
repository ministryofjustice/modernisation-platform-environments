
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

# resource "aws_s3_bucket_policy" "loadbalancer_logs" {
#   bucket = module.s3-bucket.bucket.id
#   policy = data.aws_iam_policy_document.loadbalancer_logs.json
# }

# data "aws_iam_policy_document" "loadbalancer_logs" {
#   source_policy_documents = [module.s3-bucket.bucket.policy.json]

#   # policy from: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html#access-logging-bucket-permissions
#   statement {
#     effect    = "Allow"
#     actions   = ["s3:PutObject"]
#     resources = ["${module.s3-bucket.bucket.arn}/loadbalancer-logs/AWSLogs/${local.environment_management.account_ids[terraform.workspace]}/*"]
#     principals {
#       identifiers = ["arn:aws:iam::652711504416:root"]
#       type        = "AWS"
#     }
#   }

#   statement {
#     effect    = "Allow"
#     actions   = ["s3:PutObject"]
#     resources = ["${module.s3-bucket.bucket.arn}/loadbalancer-logs/AWSLogs/${local.environment_management.account_ids[terraform.workspace]}/*"]
#     principals {
#       identifiers = ["delivery.logs.amazonaws.com"]
#       type        = "Service"
#     }
#     condition {
#       test     = "StringEquals"
#       variable = "s3:x-amz-acl"
#       values   = ["bucket-owner-full-control"]
#     }
#   }

#   statement {
#     effect    = "Allow"
#     actions   = ["s3:GetBucketAcl"]
#     resources = ["${module.s3-bucket.bucket.arn}"]
#     principals {
#       identifiers = ["delivery.logs.amazonaws.com"]
#       type        = "Service"
#     }
#   }
# }

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

