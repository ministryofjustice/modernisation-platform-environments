terraform {
  required_providers {
    aws = {
      version = "~> 5.0"
      source  = "hashicorp/aws"
    }
  }
  required_version = "~> 1.0"
}

data "aws_caller_identity" "current" {}

module "this-bucket" {
  source   = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=f759060"

  bucket_prefix      = "${var.local_bucket_prefix}-land-${var.data_feed}-${var.order_type}-"
  versioning_enabled = false

  # to disable ACLs in preference of BucketOwnership controls as per https://aws.amazon.com/blogs/aws/heads-up-amazon-s3-security-changes-are-coming-in-april-of-2023/ set:
  ownership_controls = "BucketOwnerEnforced"
  acl                = "private"

  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below variable and providers configuration is only relevant if 'replication_enabled' is set to true
  # replication_region                       = "eu-west-2"
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
    # Leave this provider block in even if you are not using replication
    aws.bucket-replication = aws
  }
  log_buckets = tomap({
    "log_bucket_name" : var.logging_bucket.bucket.id,
    "log_bucket_arn" : var.logging_bucket.bucket.arn,
    "log_bucket_policy" : var.logging_bucket.bucket_policy.policy,
  })
  log_prefix                = "logs/${var.local_bucket_prefix}-land-${var.data_feed}-${var.order_type}/"
  log_partition_date_source = "EventTime"

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      expiration = {
        days = 7
      }
    }
  ]

  tags = merge(
    var.local_tags,
    { type = var.order_type },
    { data_feed = var.data_feed }
  )
}

#tfsec:ignore:aws-iam-no-user-attached-policies
resource "aws_iam_user" "supplier" {
  name = "${var.local_bucket_prefix}-${var.data_feed}-${var.order_type}"
  tags = var.local_tags
}

resource "aws_iam_role" "supplier_data_access" {
  name = "supplier-put-${var.data_feed}-${var.order_type}-landing-bucket"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  managed_policy_arns = [aws_iam_policy.supplier_data_access.arn]

  tags = merge(
    var.local_tags,
    { type = var.order_type },
    { data_feed = var.data_feed }
  )
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${aws_iam_user.supplier.name}"]
    }
  }
}

resource "aws_iam_policy" "supplier_data_access" {
  name        = "put-s3-${var.data_feed}-${var.order_type}-policy"
  description = "Give put access to the ${var.data_feed}-${var.order_type} landing bucket"
  policy      = data.aws_iam_policy_document.supplier_data_access.json
}

data "aws_iam_policy_document" "supplier_data_access" {
  # Source bucket access
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionTagging"
    ]

    resources = [
      "arn:aws:s3:::awsexamplesourcebucket",
      "arn:aws:s3:::awsexamplesourcebucket/*"
    ]
  }
  # Destination bucket access
  statement {
    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${module.this-bucket.bucket.arn}/*",
    ]
  }
}
