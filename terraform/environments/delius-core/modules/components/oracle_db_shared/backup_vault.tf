resource "aws_backup_vault" "oracle_backup_vault" {
  name        = "${var.env_name}-${var.db_suffix}-oracle-backup-vault"
  kms_key_arn = var.account_config.kms_keys.general_shared
  tags = merge(
    var.tags,
    {
      "Name" = "${var.env_name}-${var.db_suffix}-oracle-backup-vault"
    },
  )
}

# Allow the AWSBackupDefaultServiceRole role to be passed to the instance roles.
# We use Backup Vault to manage EC2 snapshots for Oracle hosts as these are only created sporadically, 
# e.g. ahead of a service release, and will therefore not be continually overwritten.  Writing them to a
# backup vault allows them to timeout without being overwritten.
# The AWSBackupDefaultServiceRole managed by AWS and is documented at: 
# https://docs.aws.amazon.com/aws-backup/latest/devguide/iam-service-roles.html
data "aws_iam_policy_document" "oracle_ec2_snapshot_backup_role_policy_document" {
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${var.account_info.id}:role/service-role/AWSBackupDefaultServiceRole"]
  }
  statement {
    effect = "Allow"
    actions = ["backup:ListBackupVaults",
      "backup:StartBackupJob",
      "backup:DescribeBackupJob",
    "ec2:DescribeSnapshots"]
    resources = ["*"]
  }
  statement {
    actions = [
      "kms:GenerateDataKey",
      "kms:Encrypt",
      "kms:Decrypt",
    ]
    resources = [var.account_config.kms_keys.general_shared]
  }
}

### DEBUG ONLY
# S3 bucket to store CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "${var.env_name}-cloudtrail-debug-logs-bucket"
  force_destroy = true
}

# Bucket policy to allow CloudTrail to write to the S3 bucket
resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck",
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action    = "s3:GetBucketAcl",
        Resource  = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid       = "AWSCloudTrailWrite",
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action    = "s3:PutObject",
        Resource  = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# Get current account ID for bucket path
data "aws_caller_identity" "current" {}

# CloudTrail trail
resource "aws_cloudtrail" "my_trail" {
  name                          = "${var.env_name}-debug-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
}


