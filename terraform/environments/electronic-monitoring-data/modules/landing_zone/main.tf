#------------------------------------------------------------------------------
# S3 bucket for landing Supplier data
#
# Lifecycle management not implemented for this bucket as everything will be
# moved to a different bucket once landed.
#------------------------------------------------------------------------------

resource "random_string" "this" {
  length  = 10
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "aws_s3_bucket" "landing_bucket" {
  bucket = "${var.supplier}-${random_string.this.result}"

  tags = merge(
    var.local_tags,
    {
      supplier = var.supplier,
    },
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "landing_bucket" {
  bucket = aws_s3_bucket.landing_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "landing_bucket" {
  bucket                  = aws_s3_bucket.landing_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "landing_bucket" {
  bucket = aws_s3_bucket.landing_bucket.id
  policy = data.aws_iam_policy_document.landing_bucket.json
}

data "aws_iam_policy_document" "landing_bucket" {
  statement {
    sid = "EnforceTLSv12orHigher"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.landing_bucket.arn,
      "${aws_s3_bucket.landing_bucket.arn}/*"
    ]
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = [1.2]
    }
  }
}

resource "aws_s3_bucket_versioning" "landing_bucket" {
  bucket = aws_s3_bucket.landing_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_logging" "landing_bucket" {
  bucket = aws_s3_bucket.landing_bucket.id

  target_bucket = module.log_bucket.bucket_id
  target_prefix = "log/"

  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}

#------------------------------------------------------------------------------
# S3 bucket for landing bucket logs
#------------------------------------------------------------------------------

module "log_bucket" {
  source = "../s3_log_bucket"

  source_bucket = aws_s3_bucket.landing_bucket
  account_id    = var.account_id

  local_tags = var.local_tags
  tags = {
      supplier = var.supplier
  }
}

#------------------------------------------------------------------------------
# AWS KMS for encrypting cloudwatch logs
#------------------------------------------------------------------------------

resource "aws_kms_key" "this" {
  description             = "${var.supplier} server cloudwatch log encryption key"
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 30

  tags = merge(
    var.local_tags,
    {
      supplier = var.supplier,
    },
  )
}

resource "aws_kms_key_policy" "this" {
  key_id = aws_kms_key.this.id
  policy = jsonencode({
    Id = "${var.supplier}-cloudwatch"
    Statement = [
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Resource = "*"
        Sid      = "Enable IAM User Permissions"
      },
      {
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Effect = "Allow"
        Principal = {
          Service = "logs.eu-west-2.amazonaws.com"
        }
        Resource = "*"
        Sid      = "Enable log service Permissions"
      }
    ]
    Version = "2012-10-17"
  })
}

#------------------------------------------------------------------------------
# AWS elastic IP
#
# Assign unique IP for each supplier to connect to.
#------------------------------------------------------------------------------

resource "aws_eip" "this" {
  domain = "vpc"

  tags = merge(
    var.local_tags,
    {
      supplier = var.supplier,
    },
  )
}

#------------------------------------------------------------------------------
# AWS transfer server 
#
# Configure SFTP server for supplier that only allows supplier specified IPs.
#------------------------------------------------------------------------------

module "sftp_server" {
  source = "./landing_zone_server"

  count = var.create_server ? 1 : 0

  data_store_bucket = var.data_store_bucket
  eip_id            = aws_eip.this.id
  kms_key           = aws_kms_key.this
  landing_bucket    = aws_s3_bucket.landing_bucket
  local_tags        = var.local_tags
  subnet_ids        = var.subnet_ids
  supplier          = var.supplier
  user_accounts     = var.user_accounts
  vpc_id            = var.vpc_id
}
