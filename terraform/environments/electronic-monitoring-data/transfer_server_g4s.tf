#------------------------------------------------------------------------------
# AWS elastic IP
#
# Assign unique IP for each supplier to connect to.
#------------------------------------------------------------------------------

resource "aws_eip" "g4s" {
  domain = "vpc"
}

#------------------------------------------------------------------------------
# AWS transfer server 
#
# Configure SFTP server for supplier that only allows supplier specified IPs.
#------------------------------------------------------------------------------

resource "aws_transfer_server" "g4s" {
  protocols              = ["SFTP"]
  identity_provider_type = "SERVICE_MANAGED"

  endpoint_type = "VPC"
  endpoint_details {
    vpc_id                 = data.aws_vpc.shared.id
    subnet_ids             = [data.aws_subnet.public_subnets_b.id]
    address_allocation_ids = [aws_eip.g4s.id]
    security_group_ids     = [
      aws_security_group.g4s.id,
      aws_security_group.test.id
    ]
  }

  domain = "S3"

  security_policy_name = "TransferSecurityPolicy-2023-05"

  pre_authentication_login_banner = "Hello there"

  workflow_details {
    on_upload {
      workflow_id    = aws_transfer_workflow.transfer_g4s_to_store.id
      execution_role = aws_iam_role.g4s_transfer_workflow_iam_role.arn
    }
  }

  logging_role = aws_iam_role.iam_for_transfer_g4s.arn
  structured_log_destinations = [
    "${aws_cloudwatch_log_group.g4s.arn}:*"
  ]
}

resource "aws_iam_role" "iam_for_transfer_g4s" {
  name_prefix         = "iam-for-transfer-g4s-"
  assume_role_policy  = data.aws_iam_policy_document.transfer_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"]
}

resource "aws_cloudwatch_log_group" "g4s" {
  name_prefix = "transfer_g4s_"
}
#------------------------------------------------------------------------------
# AWS transfer workflow
#
# For files that arrive in the landing bucket:
# 1. copy the file to the internal data store bucket
# 2. delete the file from the landing bucket
#------------------------------------------------------------------------------

resource "aws_transfer_workflow" "transfer_g4s_to_store" {
  steps {
    copy_step_details {
      source_file_location = "$${original.file}"
      destination_file_location {
        s3_file_location {
          bucket = aws_s3_bucket.data_store_bucket.bucket
          key    = "g4s/"
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

resource "aws_iam_role" "g4s_transfer_workflow_iam_role" {
  name                = "g4s-transfer-workflow-iam-role"
  assume_role_policy  = data.aws_iam_policy_document.transfer_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"]
}

data "aws_iam_policy_document" "g4s_transfer_workflow_iam_policy_document" {
  statement {
    sid    = "AllowCopyReadSource"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectTagging"
    ]
    resources = ["${aws_s3_bucket.g4s_landing_bucket.arn}/*"]
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
      aws_s3_bucket.g4s_landing_bucket.arn,
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
      "${aws_s3_bucket.g4s_landing_bucket.arn}/*",
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
    resources = ["${aws_s3_bucket.g4s_landing_bucket.arn}/*"]
  }
}

resource "aws_iam_role_policy" "g4s_transfer_workflow_iam_policy" {
  name   = "g4s-transfer-workflow-iam-policy"
  role   = aws_iam_role.g4s_transfer_workflow_iam_role.id
  policy = data.aws_iam_policy_document.g4s_transfer_workflow_iam_policy_document.json
}
