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
    address_allocation_ids = [var.eip_id]
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
  kms_key_id        = var.kms_key.arn
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
    resources = ["${var.landing_bucket.arn}/*"]
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
      var.landing_bucket.arn,
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
      "${var.landing_bucket.arn}/*",
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
    resources = ["${var.landing_bucket.arn}/*"]
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
  source = "../landing_zone_user"

  for_each = { for idx, item in var.user_accounts : idx => item }

  landing_bucket     = var.landing_bucket
  local_tags         = var.local_tags
  ssh_keys           = each.value.ssh_keys
  supplier           = var.supplier
  transfer_server_id = aws_transfer_server.this.id
  user_name          = each.value.name
}

#------------------------------------------------------------------------------
# AWS security group 
#
# Set the allowed IP addresses for the this SFTP server.
#------------------------------------------------------------------------------

module "landing_zone_security_groups" {
  source = "../server_security_group"

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
