#------------------------------------------------------------------------------
# AWS elastic IP
#
# Assign unique IP for each supplier to connect to.
#------------------------------------------------------------------------------

resource "aws_eip" "capita_eip" {
  domain = "vpc"
}

#------------------------------------------------------------------------------
# AWS transfer server 
#
# Configure SFTP server for supplier that only allows supplier specified IPs.
#------------------------------------------------------------------------------

resource "aws_transfer_server" "capita_transfer_server" {
  protocols              = ["SFTP"]
  identity_provider_type = "SERVICE_MANAGED"

  endpoint_type = "VPC"
  endpoint_details {
    vpc_id                 = data.aws_vpc.shared.id
    subnet_ids             = [data.aws_subnet.public_subnets_b.id]
    address_allocation_ids = [aws_eip.capita_eip.id]
    security_group_ids     = [
      aws_security_group.capita_security_group.id,
      aws_security_group.test_security_group.id
    ]
  }

  domain = "S3"

  security_policy_name = "TransferSecurityPolicy-2023-05"

  pre_authentication_login_banner = "Hello there"

  workflow_details {
    on_upload {
      workflow_id    = aws_transfer_workflow.transfer_capita_to_store.id
      execution_role = aws_iam_role.capita_transfer_workflow_iam_role.arn
    }
  }

  logging_role = aws_iam_role.test_transfer_user_iam_role.arn
  structured_log_destinations = [
    "${aws_cloudwatch_log_group.capita.arn}:*"
  ]
}

resource "aws_cloudwatch_log_group" "capita" {
  name_prefix = "transfer_test_"
}

#------------------------------------------------------------------------------
# AWS transfer workflow
#
# For files that arrive in the landing bucket:
# 1. copy the file to the internal data store bucket
# 2. delete the file from the landing bucket
#------------------------------------------------------------------------------

resource "aws_transfer_workflow" "transfer_capita_to_store" {
  steps {
    copy_step_details {
      source_file_location = "$${original.file}"
      destination_file_location {
        s3_file_location {
          bucket = aws_s3_bucket.data_store_bucket.bucket
          key    = "capita/"
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

data "aws_iam_policy_document" "capita_transfer_workflow_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "capita_transfer_workflow_iam_role" {
  name                = "capita-transfer-workflow-iam-role"
  assume_role_policy  = data.aws_iam_policy_document.capita_transfer_workflow_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"]
}

data "aws_iam_policy_document" "capita_transfer_workflow_iam_policy_document" {
  statement {
    sid    = "AllowCopyReadSource"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectTagging"
    ]
    resources = ["${aws_s3_bucket.capita_landing_bucket.arn}/*"]
  }
  statement {
    sid    = "AllowCopyWriteDestination"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging"
    ]
    resources = ["${aws_s3_bucket.data_store_bucket.arn}/*"]
  }
  statement {
    sid    = "AllowCopyList"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.capita_landing_bucket.arn,
      aws_s3_bucket.data_store_bucket.arn
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
      "${aws_s3_bucket.data_store_bucket.arn}/*",
      "${aws_s3_bucket.capita_landing_bucket.arn}/*",
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
    resources = ["${aws_s3_bucket.capita_landing_bucket.arn}/*"]
  }
}

resource "aws_iam_role_policy" "capita_transfer_workflow_iam_policy" {
  name   = "capita-transfer-workflow-iam-policy"
  role   = aws_iam_role.capita_transfer_workflow_iam_role.id
  policy = data.aws_iam_policy_document.capita_transfer_workflow_iam_policy_document.json
}
