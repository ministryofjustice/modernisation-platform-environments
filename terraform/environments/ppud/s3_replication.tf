##########################################################################################
# S3 Replication Buckets (database-source & report-source) for DEV, UAT, PROD
# Optimised replacement for s3.tf lines 282-443, 447-604, 1017-1174, 1178-1336, 1559-1716, 1720-1877
##########################################################################################

locals {
  s3_replication_buckets = {
    for k, v in {
      database_dev = {
        condition       = local.is-development
        bucket_name     = "moj-database-source-dev"
        log_bucket      = "moj-log-files-dev"
        log_prefix      = "s3-logs/moj-database-source-dev-logs/"
        lifecycle_id    = "delete-moj-database-source-dev"
        expiration_days = 6
        replication_destination = "arn:aws:s3:::mojap-data-engineering-production-ppud-dev"
        replication_rule_id     = "ppud-database-replication-rule-dev"
        iam_role_key            = "database_dev"
        ec2_account             = "ppud-development"
      }
      report_dev = {
        condition       = local.is-development
        bucket_name     = "moj-report-source-dev"
        log_bucket      = "moj-log-files-dev"
        log_prefix      = "s3-logs/moj-report-source-dev-logs/"
        lifecycle_id    = "delete-moj-report-source-dev"
        expiration_days = 6
        replication_destination = "arn:aws:s3:::cloud-platform-db973d65892f599f6e78cb90252d7dc9"
        replication_rule_id     = "ppud-report-replication-rule-dev"
        iam_role_key            = "report_dev"
        ec2_account             = "ppud-development"
      }
      database_uat = {
        condition       = local.is-preproduction
        bucket_name     = "moj-database-source-uat"
        log_bucket      = "moj-log-files-uat"
        log_prefix      = "s3-logs/moj-database-source-uat-logs/"
        lifecycle_id    = "delete-moj-database-source-uat"
        expiration_days = 6
        replication_destination = "arn:aws:s3:::mojap-data-engineering-production-ppud-preprod"
        replication_rule_id     = "ppud-database-replication-rule-uat"
        iam_role_key            = "database_uat"
        ec2_account             = "ppud-preproduction"
      }
      report_uat = {
        condition       = local.is-preproduction
        bucket_name     = "moj-report-source-uat"
        log_bucket      = "moj-log-files-uat"
        log_prefix      = "s3-logs/moj-report-source-uat-logs/"
        lifecycle_id    = "delete-moj-report-source-uat"
        expiration_days = 6
        replication_destination = "arn:aws:s3:::cloud-platform-ffbd9073e2d0d537d825ebea31b441fc"
        replication_rule_id     = "ppud-report-replication-rule-uat"
        iam_role_key            = "report_uat"
        ec2_account             = "ppud-preproduction"
      }
      database_prod = {
        condition       = local.is-production
        bucket_name     = "moj-database-source-prod"
        log_bucket      = "moj-log-files-prod"
        log_prefix      = "s3-logs/moj-database-source-prod-logs/"
        lifecycle_id    = "delete-moj-database-source-prod"
        expiration_days = 6
        replication_destination = "arn:aws:s3:::mojap-data-engineering-production-ppud-prod"
        replication_rule_id     = "ppud-report-replication-rule-prod"
        iam_role_key            = "database_prod"
        ec2_account             = "ppud-production"
      }
      report_prod = {
        condition       = local.is-production
        bucket_name     = "moj-report-source-prod"
        log_bucket      = "moj-log-files-prod"
        log_prefix      = "s3-logs/moj-report-source-prod-logs/"
        lifecycle_id    = "delete-moj-report-source-prod"
        expiration_days = 6
        replication_destination = "arn:aws:s3:::cloud-platform-9c7fd5fc774969b089e942111a7d5671"
        replication_rule_id     = "ppud-report-replication-rule-prod"
        iam_role_key            = "report_prod"
        ec2_account             = "ppud-production"
      }
    } : k => v if v.condition
  }

  # Log bucket ARN lookup used in replication bucket policies
  log_bucket_arns = {
    "moj-log-files-dev"  = local.is-development ? aws_s3_bucket.moj-log-files-dev[0].arn : ""
    "moj-log-files-uat"  = local.is-preproduction ? aws_s3_bucket.moj-log-files-uat[0].arn : ""
    "moj-log-files-prod" = local.is-production ? aws_s3_bucket.moj-log-files-prod[0].arn : ""
  }
}


resource "aws_s3_bucket" "s3_replication" {
  # checkov:skip=CKV_AWS_145: "S3 bucket is not public facing, does not contain any sensitive information and does not need encryption"
  # checkov:skip=CKV_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV2_AWS_62: "S3 bucket event notification is not required"
  # checkov:skip=CKV_AWS_144: "PPUD has a UK Sovereignty requirement so cross region replication is prohibited"
  for_each = local.s3_replication_buckets
  bucket   = each.value.bucket_name
  tags = merge(local.tags, {
    Name = "${local.application_name}-${each.value.bucket_name}"
  })
}

resource "aws_s3_bucket_versioning" "s3_replication" {
  for_each = local.s3_replication_buckets
  bucket   = aws_s3_bucket.s3_replication[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "s3_replication" {
  for_each      = local.s3_replication_buckets
  bucket        = aws_s3_bucket.s3_replication[each.key].id
  target_bucket = each.value.log_bucket
  target_prefix = each.value.log_prefix
}

resource "aws_s3_bucket_public_access_block" "s3_replication" {
  for_each                = local.s3_replication_buckets
  bucket                  = aws_s3_bucket.s3_replication[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_replication" {
  # checkov:skip=CKV_AWS_300: "S3 bucket has a set period for aborting failed uploads, this is a false positive finding"
  for_each = local.s3_replication_buckets
  bucket   = aws_s3_bucket.s3_replication[each.key].id
  rule {
    id     = each.value.lifecycle_id
    status = "Enabled"
    filter {
      prefix = ""
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 3
    }
    expiration {
      days = each.value.expiration_days
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "s3_replication" {
  for_each   = local.s3_replication_buckets
  depends_on = [aws_s3_bucket_versioning.s3_replication]
  role       = aws_iam_role.s3_replication[each.value.iam_role_key].arn
  bucket     = aws_s3_bucket.s3_replication[each.key].id

  rule {
    id     = each.value.replication_rule_id
    status = "Enabled"
    filter {}
    delete_marker_replication {
      status = "Disabled"
    }
    destination {
      bucket        = each.value.replication_destination
      storage_class = "STANDARD"
    }
  }
}

resource "aws_s3_bucket_policy" "s3_replication" {
  for_each = local.s3_replication_buckets
  bucket   = aws_s3_bucket.s3_replication[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "RequireSSLRequests"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.s3_replication[each.key].arn,
          "${aws_s3_bucket.s3_replication[each.key].arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
      {
        Effect = "Allow"
        Action = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.s3_replication[each.key].arn,
          "${aws_s3_bucket.s3_replication[each.key].arn}/*"
        ]
        Principal = {
          AWS = ["arn:aws:iam::${local.environment_management.account_ids[each.value.ec2_account]}:role/ec2-iam-role"]
        }
      },
      {
        Effect = "Allow"
        Action = ["s3:PutBucketNotification", "s3:GetBucketNotification", "s3:GetBucketAcl", "s3:DeleteObject", "s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.s3_replication[each.key].arn,
          "${aws_s3_bucket.s3_replication[each.key].arn}/*"
        ]
        Principal = { Service = "logging.s3.amazonaws.com" }
      },
      {
        Effect = "Allow"
        Action = ["s3:PutBucketNotification", "s3:GetBucketNotification", "s3:GetBucketAcl", "s3:DeleteObject", "s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.s3_replication[each.key].arn,
          "${aws_s3_bucket.s3_replication[each.key].arn}/*"
        ]
        Principal = { Service = "sns.amazonaws.com" }
      }
    ]
  })
}


##########################################################################################
# S3 Bucket Roles and Policies for S3 Buckets that replicate to Justice Digital S3 Buckets
# Optimised replacement for iam.tf lines 214-662
##########################################################################################

locals {
  s3_replication_configs = local.s3_replication_buckets
}

resource "aws_iam_role" "s3_replication" {
  for_each = local.s3_replication_configs
  name     = "iam_role_s3_bucket_moj_${each.key}"
  path     = "/service-role/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "s3_replication" {
  for_each    = local.s3_replication_configs
  name        = "iam_policy_s3_bucket_moj_${each.key}"
  path        = "/"
  description = "AWS IAM Policy for allowing s3 bucket cross account replication"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SourceBucketPermissions"
        Effect = "Allow"
        Action = [
          "s3:GetObjectRetention",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectVersionAcl",
          "s3:ListBucket",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectLegalHold",
          "s3:GetReplicationConfiguration"
        ]
        Resource = [
          aws_s3_bucket.s3_replication[each.key].arn,
          "${aws_s3_bucket.s3_replication[each.key].arn}/*"
        ]
      },
      {
        Sid    = "DestinationBucketPermissions"
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ObjectOwnerOverrideToBucketOwner",
          "s3:GetObjectVersionTagging",
          "s3:ReplicateTags",
          "s3:ReplicateDelete"
        ]
        Resource = [
          each.value.replication_destination,
          "${each.value.replication_destination}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_replication" {
  for_each   = local.s3_replication_configs
  role       = aws_iam_role.s3_replication[each.key].name
  policy_arn = aws_iam_policy.s3_replication[each.key].arn
}
