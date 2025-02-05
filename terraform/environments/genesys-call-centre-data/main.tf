#trivy:ignore:AVD-AWS-0102
module "s3_staging" {
  source = "../.."
  providers = {
    aws.bucket-replication = aws.bucket-replication
  }
}


# AWS S3 Bucket (Call Centre Staging)
resource "aws_s3_bucket" "default" {
  #checkov:skip=CKV_AWS_144: "Replication handled in replication configuration resource"
  #checkov:skip=CKV_AWS_18: "Logging handled in logging configuration resource"
  #checkov:skip=CKV_AWS_21: "Versioning handled in Versioning configuration resource"
  #checkov:skip=CKV_AWS_145: "Encryption handled in encryption configuration resource"
  #checkov:skip=CKV2_AWS_61:
  bucket = var.call_centre_staging_aws_s3_bucket
}

resource "aws_s3_bucket" "replication" {
  #checkov:skip=CKV_AWS_144: "Replication not required on replication bucket"
  #checkov:skip=CKV_AWS_18: "Logging handled in logging configuration resource"
  #checkov:skip=CKV_AWS_21: "Versioning handled in versioning configuration resource"
  #checkov:skip=CKV_AWS_145: "Encryption handled in encryption configuration resource"
  count         = var.replication_enabled ? 1 : 0
  provider      = aws.bucket-replication
  bucket        = var.bucket_name != null ? "${var.bucket_name}-replication" : null
  bucket_prefix = var.bucket_prefix != null ? "${var.bucket_prefix}-replication" : null
  force_destroy = var.force_destroy
}

# Event Notifications for S3 buckets
resource "aws_s3_bucket_notification" "default" {
  count  = var.replication_enabled && var.notification_enabled ? 1 : 0
  bucket = aws_s3_bucket.default.id

  topic {
    topic_arn = var.notification_sns_arn
    events    = var.notification_events
  }
}

resource "aws_s3_bucket_notification" "replication" {
  count  = var.replication_enabled ? 1 : 0
  bucket = aws_s3_bucket.replication[count.index].id

  topic {
    topic_arn = var.notification_sns_arn
    events    = var.notification_events
  }
}

# tfsec:ignore:aws-s3-encryption-customer-key
#tfsec:ignore:avd-aws-0132 S3 encryption should use Custom Managed Keys, KMS is acceptable compromise 
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  #checkov:skip=CKV2_AWS_67: "Ensure AWS S3 bucket encrypted with Customer Managed Key (CMK) has regular rotation"
  bucket = aws_s3_bucket.default.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = (var.custom_kms_key != "") ? var.custom_kms_key : ""
    }
  }
}

# Enable Versioning on S3 Buckets
resource "aws_s3_bucket_versioning" "default" {
  bucket = aws_s3_bucket.default.id
  versioning_configuration {
    status = var.versioning_enabled
  }
}

# Configure bucket lifecycle rules
resource "aws_s3_bucket_lifecycle_configuration" "replication" {
  #checkov:skip=CKV_AWS_300: "Ensure S3 lifecycle configuration sets period for aborting failed uploads"
  count    = var.replication_enabled ? 1 : 0
  provider = aws.bucket-replication
  bucket   = aws_s3_bucket.replication[count.index].id
  rule {
    id     = "main"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    expiration {
      days = 730
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 365
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 730
    }
  }
}

# AWS S3 Bucket Logging
resource "aws_s3_bucket_logging" "default" {
  count = var.log_buckets != null ? 1 : 0

  bucket        = aws_s3_bucket.default.id
  target_bucket = var.log_bucket_name
  target_prefix = var.log_prefix

  dynamic "target_object_key_format" {
    for_each = (var.log_partition_date_source != "None") ? [1] : []
    content {
      partitioned_prefix {
        partition_date_source = var.log_partition_date_source
      }
    }
  }
}

# AWS S3 bucket Public Access Block (Call Centre Staging)
resource "aws_s3_bucket_public_access_block" "default" {
  bucket                  = aws_s3_bucket.default.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "replication" {
  count                   = var.replication_enabled ? 1 : 0
  bucket                  = aws_s3_bucket.replication[count.index].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket replication: role
resource "aws_iam_role" "replication" {
  provider           = aws.bucket-replication
  count              = var.replication_enabled ? 1 : 0
  name               = "AWSS3BucketReplication${var.suffix_name}"
  assume_role_policy = data.aws_iam_policy_document.s3-assume-role-policy.json
  # tags               = var.tags
}

# S3 bucket replication: assume role policy
data "aws_iam_policy_document" "s3-assume-role-policy" {
  version = var.json_encode_decode_version
  statement {
    effect  = var.moj_aws_iam_policy_document_statement_effect
    actions = var.moj_aws_iam_policy_document_statement_actions

    principals {
      type        = var.moj_aws_iam_policy_document_principals_type
      identifiers = var.moj_aws_iam_policy_document_principals_identifiers
    }
  }
}

# AWS S3 Bucket cross-region replication
resource "aws_s3_bucket_replication_configuration" "default" {
  for_each = var.replication_enabled ? toset(["run"]) : []
  bucket   = aws_s3_bucket.default.id
  role     = aws_iam_role.replication[0].arn
  rule {
    id       = var.moj_aws_s3_bucket_replication_configuration_rule_id
    status   = var.replication_enabled ? "Enabled" : "Disabled"
    priority = 0

    destination {
      # bucket        = var.replication_enabled ? aws_s3_bucket.replication[0].arn : aws_s3_bucket.replication[0].arn
      bucket        = aws_s3_bucket.default.arn
      storage_class = var.moj_aws_s3_bucket_replication_configuration_rule_destination_storage_class
      encryption_configuration {
        replica_kms_key_id = (var.custom_replication_kms_key != "") ? var.custom_replication_kms_key : "arn:aws:kms:${var.replication_region}:${data.aws_caller_identity.current.account_id}:alias/aws/s3"
      }
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = (var.replication_enabled != false) ? "Enabled" : "Disabled"
      }
    }
  }
  depends_on = [
    aws_s3_bucket_versioning.default
  ]
}

# AWS S3 Bucket Policy (Call Centre Staging)
resource "aws_s3_bucket_policy" "default" {
  bucket = var.call_centre_staging_aws_s3_bucket
  policy = jsonencode({
    Version = var.json_encode_decode_version,
    Statement = [
      {
        Sid    = var.moj_aws_s3_bucket_policy_statement_sid,
        Effect = var.moj_aws_s3_bucket_policy_statement_effect,
        Principal = {
          Service : var.moj_aws_s3_bucket_policy_statement_principal_service
        },
        Action   = var.moj_aws_s3_bucket_policy_statement_action,
        Resource = "arn:aws:s3:::${aws_s3_bucket.default.id}/*"
      },
      {
        Sid    = var.bt_genesys_aws_s3_bucket_policy_statement_sid,
        Effect = var.bt_genesys_aws_s3_bucket_policy_statement_effect,
        Principal = {
          AWS = var.bt_genesys_aws_s3_bucket_policy_statement_principal_aws
        },
        Action   = var.bt_genesys_aws_s3_bucket_policy_statement_action,
        Resource = "arn:aws:s3:::${aws_s3_bucket.default.id}/*"
      }
    ]
  })
}

# AWS GuardDuty Detector (Call Centre Staging)
resource "aws_guardduty_detector" "default" {
  enable = var.aws_guardduty_detector_enable
}

resource "aws_guardduty_organization_configuration" "default" {
  # auto_enable = true
  auto_enable_organization_members = "ALL"
  detector_id                      = aws_guardduty_detector.default.id
}

# AWS GuardDuty Organization Admin Account (Call Centre Staging)
resource "aws_guardduty_organization_admin_account" "default" {
  admin_account_id = var.aws_guardduty_organization_admin_account_id_string
  depends_on       = [aws_guardduty_detector.default]
}

# AWS GuardDuty Member (Call Centre Staging)
resource "aws_guardduty_member" "default" {
  for_each                   = toset(var.aws_guardduty_organization_admin_account_id_list)
  account_id                 = each.key
  detector_id                = aws_guardduty_detector.default.id
  email                      = var.aws_guardduty_member_email
  invite                     = var.aws_guardduty_member_invite
  disable_email_notification = var.aws_guardduty_member_disable_email_notification
}

# AWS GuardDuty Publishing Destination (Call Centre Staging)
resource "aws_guardduty_publishing_destination" "default" {
  detector_id     = aws_guardduty_detector.default.id
  destination_arn = aws_s3_bucket.default.arn
  kms_key_arn     = aws_kms_key.s3.arn
  depends_on = [
    aws_s3_bucket.default,
    aws_s3_bucket_policy.default
  ]
}

# AWS KMS Key (Call Centre Staging)
resource "aws_kms_key" "s3" {
  #checkov:skip=CKV_AWS_7
  description = var.aws_kms_key_s3_description
  key_usage   = var.aws_kms_key_s3_key_usage
  policy = jsonencode({
    Version = var.json_encode_decode_version,
    Statement = [
      {
        Sid    = var.aws_kms_key_s3_policy_statement_sid,
        Effect = var.aws_kms_key_s3_policy_statement_effect,
        Principal = {
          Service = var.aws_kms_key_s3_policy_statement_principal_service
        },
        Action   = var.aws_kms_key_s3_policy_statement_action,
        Resource = var.aws_kms_key_s3_policy_statement_resource
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

#####
# # Network ACL rule ...
# resource "aws_flow_log" "default" {
#   iam_role_arn    = "arn"
#   log_destination = "log"
#   traffic_type    = "ALL"
#   vpc_id          = aws_vpc.ok_vpc.id
# }

# resource "aws_vpc" "ok_vpc" {
#   cidr_block = "10.0.0.0/16"
# }

# resource "aws_vpc" "issue_vpc" {
#   cidr_block = "10.0.0.0/16"
# }

resource "aws_default_security_group" "default" {
  vpc_id = "acl-04ab36970f6f08063"

  ingress {
    protocol  = "6"
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "main" {
  vpc_id     = "acl-04ab36970f6f08063"
  cidr_block = "10.0.1.0/24"
}

resource "aws_network_acl" "acl_ok" {
  vpc_id = "acl-04ab36970f6f08063"
  subnet_ids = [
    "subnet-0bb27b9eb632f03b1",
    "subnet-03c0d6913df01115e",
    "subnet-0a318473cd5c8c09b"
  ]
}

#checkov:skip=AVD-AWS-0102
resource "aws_network_acl" "default" {
  #checkov:skip=CKV2_AWS_1
  vpc_id = "acl-04ab36970f6f08063"
  subnet_ids = [
    "subnet-0bb27b9eb632f03b1",
    "subnet-03c0d6913df01115e",
    "subnet-0a318473cd5c8c09b"
  ]
}

#checkov:skip=AVD-AWS-0102
resource "aws_network_acl_rule" "private_inbound" {
  network_acl_id = "acl-04ab36970f6f08063"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

#checkov:skip=AVD-AWS-0102
resource "aws_network_acl_rule" "private_outbound" {
  network_acl_id = "acl-04ab36970f6f08063"
  rule_number    = 101
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}
#####

# resource "aws_vpc_endpoint" "this" {
#   vpc_id              = "vpc-0854846a32de08f57"
#   service_name        = "com.amazonaws.eu-west-2.execute-api"
#   private_dns_enabled = true
# #   subnet_ids          = var.subnet_ids
# #   security_group_ids  = var.security_group_ids
#   vpc_endpoint_type   = "Interface"

# #   tags = var.tags
# }

