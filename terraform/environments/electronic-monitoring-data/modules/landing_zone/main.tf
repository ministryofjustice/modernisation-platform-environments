data "aws_iam_policy_document" "transfer_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

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
  #checkov:skip=CKV_AWS_144:Unsure of policy on this yet, should be covered by module - See ELM-1949
  #checkov:skip=CKV_AWS_145:Decide on a KMS key for encryption, should be covered by moudle - See ELM-1949
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

resource "aws_transfer_server" "this" {
  protocols              = ["SFTP"]
  identity_provider_type = "SERVICE_MANAGED"

  endpoint_type = "VPC"
  endpoint_details {
    vpc_id                 = var.vpc_id
    subnet_ids             = var.subnet_ids
    address_allocation_ids = [aws_eip.this.id]
    security_group_ids     = local.landing_zone_security_group_ids
  }

  domain = "S3"

  security_policy_name = "TransferSecurityPolicy-2023-05"

  pre_authentication_login_banner = "\nHello there\n"

  workflow_details {
    on_upload {
      workflow_id    = aws_transfer_workflow.this.id
      execution_role = aws_iam_role.this_transfer_workflow.arn
    }
  }

  logging_role = aws_iam_role.iam_for_transfer.arn
  structured_log_destinations = [
    "${aws_cloudwatch_log_group.this.arn}:*"
  ]

  tags = merge(
    var.local_tags,
    {
      supplier = var.supplier,
    },
  )
}

resource "aws_iam_role" "iam_for_transfer" {
  name_prefix         = "${var.supplier}-iam-for-transfer-"
  assume_role_policy  = data.aws_iam_policy_document.transfer_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"]
}

resource "aws_cloudwatch_log_group" "this" {
  name_prefix       = "transfer_${var.supplier}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.this.arn
}

#------------------------------------------------------------------------------
# AWS transfer workflow
#
# For files that arrive in the landing bucket:
# 1. tag the file with the supplier who sent it
# 2. copy the file to the internal data store bucket
# 3. delete the file from the landing bucket
#------------------------------------------------------------------------------

resource "aws_transfer_workflow" "this" {
  description = "Move data from ${var.supplier} landing zone to data store"

  steps {
    tag_step_details {
      name                 = "tag-with-supplier"
      source_file_location = "$${original.file}"
      tags {
        key   = "supplier"
        value = var.supplier
      }
    }
    type = "TAG"
  }
  steps {
    copy_step_details {
      name                 = "copy-file-to-data-store"
      source_file_location = "$${original.file}"
      destination_file_location {
        s3_file_location {
          bucket = var.data_store_bucket.bucket
          key    = "${var.supplier}/$${transfer:UserName}/$${transfer:UploadDate}/"
        }
      }
    }
    type = "COPY"
  }
  steps {
    delete_step_details {
      name                 = "delete-file-from-landing-zone"
      source_file_location = "$${original.file}"
    }
    type = "DELETE"
  }

  tags = merge(
    var.local_tags,
    {
      supplier = var.supplier,
    },
  )
}

resource "aws_iam_role" "this_transfer_workflow" {
  name                = "${var.supplier}-transfer-workflow-iam-role"
  assume_role_policy  = data.aws_iam_policy_document.transfer_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"]
}

data "aws_iam_policy_document" "this_transfer_workflow" {
  statement {
    sid    = "AllowCopyReadSource"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectTagging"
    ]
    resources = ["${aws_s3_bucket.landing_bucket.arn}/*"]
  }
  statement {
    sid    = "AllowCopyWriteDestination"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging"
    ]
    resources = ["${var.data_store_bucket.arn}/*"]
  }
  statement {
    sid    = "AllowCopyList"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.landing_bucket.arn,
      var.data_store_bucket.arn
    ]
  }
  statement {
    sid    = "AllowTag"
    effect = "Allow"
    actions = [
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging"
    ]
    resources = [
      "${var.data_store_bucket.arn}/*",
      "${aws_s3_bucket.landing_bucket.arn}/*",
    ]
    # condition {}
  }
  statement {
    sid    = "AllowDeleteSource"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion"
    ]
    resources = ["${aws_s3_bucket.landing_bucket.arn}/*"]
  }
}

resource "aws_iam_role_policy" "this_transfer_workflow" {
  name   = "${var.supplier}-transfer-workflow-iam-policy"
  role   = aws_iam_role.this_transfer_workflow.id
  policy = data.aws_iam_policy_document.this_transfer_workflow.json
}

#------------------------------------------------------------------------------
# AWS transfer user
#
# Create user profiles that has put access to only this landing zone bucket.
#------------------------------------------------------------------------------

module "landing_zone_users" {
  source = "./landing_zone_user"

  for_each = { for idx, item in var.user_accounts : idx => item }

  landing_bucket  = aws_s3_bucket.landing_bucket
  local_tags      = var.local_tags
  ssh_keys        = each.value.ssh_keys
  supplier        = var.supplier
  transfer_server = aws_transfer_server.this
  user_name       = each.value.name
}

#------------------------------------------------------------------------------
# AWS security group 
#
# Set the allowed IP addresses for the this SFTP server.
#------------------------------------------------------------------------------

module "landing_zone_security_groups" {
  source = "./server_security_group"

  for_each = { for idx, item in var.user_accounts : idx => item }

  cidr_ipv4s = each.value.cidr_ipv4s
  cidr_ipv6s = each.value.cidr_ipv6s
  local_tags = var.local_tags
  supplier   = var.supplier
  user_name  = each.value.name
  vpc_id     = var.vpc_id
}

locals {
  landing_zone_security_group_ids = flatten([
    for module_instance in values(module.landing_zone_security_groups) :
    module_instance.security_group_id
  ])
}
