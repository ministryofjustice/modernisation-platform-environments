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
  bucket = "${var.supplier}-${random_string.this.result}"
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

  target_bucket = var.log_bucket.id
  target_prefix = "log/${var.supplier}/"

  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}

#------------------------------------------------------------------------------
# AWS elastic IP
#
# Assign unique IP for each supplier to connect to.
#------------------------------------------------------------------------------

resource "aws_eip" "this" {
  domain = "vpc"
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
    security_group_ids     = [
      aws_security_group.this.id,
      aws_security_group.dev.id
    ]
  }

  domain = "S3"

  tags = {
    Name = var.supplier
  }

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
}

resource "aws_iam_role" "iam_for_transfer" {
  name_prefix         = "${var.supplier}-iam-for-transfer-"
  assume_role_policy  = data.aws_iam_policy_document.transfer_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"]
}

resource "aws_cloudwatch_log_group" "this" {
  name_prefix       = "transfer_${var.supplier}"
  retention_in_days = 365
  kms_key_id        = var.kms_key_id
}

#------------------------------------------------------------------------------
# AWS transfer workflow
#
# For files that arrive in the landing bucket:
# 1. copy the file to the internal data store bucket
# 2. delete the file from the landing bucket
#------------------------------------------------------------------------------

resource "aws_transfer_workflow" "this" {
  steps {
    copy_step_details {
      source_file_location = "$${original.file}"
      destination_file_location {
        s3_file_location {
          bucket = var.data_store_bucket.bucket
          key    = "${var.supplier}/"
        }
      }
    }
    type = "COPY"
  }
  steps {
    delete_step_details {
      source_file_location = "$${original.file}"
    }
    type = "DELETE"
  }
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
# Create supplier user profile that has put access to only their landing zone
# bucket.
#------------------------------------------------------------------------------

resource "aws_transfer_user" "this" {
  count = var.give_access ? 1 : 0

  server_id = aws_transfer_server.this.id
  user_name = var.supplier
  role      = aws_iam_role.this_transfer_user.arn

  home_directory = "/${aws_s3_bucket.landing_bucket.id}/"
}

resource "aws_iam_role" "this_transfer_user" {
  name                = "${var.supplier}-transfer-user-iam-role"
  assume_role_policy  = data.aws_iam_policy_document.transfer_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"]
}

resource "aws_iam_role_policy" "this_transfer_user" {
  name   = "${var.supplier}-transfer-user-iam-policy"
  role   = aws_iam_role.this_transfer_user.id
  policy = data.aws_iam_policy_document.this_transfer_user.json
}

data "aws_iam_policy_document" "this_transfer_user" {
  statement {
    sid       = "AllowListAccessToLandingS3"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.landing_bucket.arn]
  }
  statement {
    sid       = "AllowPutAccessToLandingS3"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.landing_bucket.arn}/*"]
  }
}

#------------------------------------------------------------------------------
# AWS transfer ssh key
#
# Set the public ssh key for the supplier user profile to access SFTP server.
#------------------------------------------------------------------------------

resource "aws_transfer_ssh_key" "this" {
  count = var.give_access ? 1 : 0

  server_id = aws_transfer_server.this.id
  user_name = aws_transfer_user.this[0].user_name
  body      = var.supplier_shh_key
}

#------------------------------------------------------------------------------
# AWS security group 
#
# Set the allowed IP addresses for the supplier.
#------------------------------------------------------------------------------

resource "aws_security_group" "this" {
  name        = "${var.supplier}-inbound-ips"
  description = "Allowed IP addresses for ${var.supplier}"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  security_group_id = aws_security_group.this.id
  description       = "Allow specific access to IP address via port 2222"
  ip_protocol       = "tcp"
  from_port         = 2222
  to_port           = 2222

  for_each  = { for cidr_ipv4 in var.supplier_cidr_ipv4s : cidr_ipv4 => cidr_ipv4 }
  cidr_ipv4 = each.key
}

#------------------------------------------------------------------------------
# Create dev account for testing
#------------------------------------------------------------------------------

resource "aws_transfer_user" "dev" {
  count = var.give_dev_access ? 1 : 0

  server_id = aws_transfer_server.this.id
  user_name = "dev"
  role      = aws_iam_role.this_transfer_user.arn

  home_directory = "/${aws_s3_bucket.landing_bucket.id}/"
}

resource "aws_transfer_ssh_key" "dev_ssh_key" {
  server_id = aws_transfer_server.this.id
  user_name = aws_transfer_user.dev[0].user_name

  for_each  = { for ssh_key in var.dev_ssh_keys : ssh_key => ssh_key }
  body      = each.key
}

resource "aws_security_group" "dev" {
  name        = "${var.supplier}-dev-inbound-ips"
  description = "Allowed MoJ developer IP addresses for testing ${var.supplier} landing zone"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "dev" {
  security_group_id = aws_security_group.dev.id

  ip_protocol = "tcp"
  from_port   = 2222
  to_port     = 2222

  for_each  = { for cidr_ipv4 in var.dev_cidr_ipv4s : cidr_ipv4 => cidr_ipv4 }
  cidr_ipv4 = each.key
}