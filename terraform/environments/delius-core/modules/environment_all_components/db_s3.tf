module "s3_bucket_oracledb_backups" {
  source              = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.0.0"
  bucket_name         = "${var.app_name}-${var.env_name}-oracledb-backups"
  versioning_enabled  = false
  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false

  providers = {
    aws.bucket-replication = aws.bucket-replication
  }

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]

      expiration = {
        days = 365
      }
    }
  ]

  tags = local.tags
}

data "aws_iam_policy_document" "oracledb_backup_bucket_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = [
      "${module.s3_bucket_oracledb_backups.bucket.arn}*/*"
    ]
  }

  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [module.s3_bucket_oracledb_backups.bucket.arn]
  }
}

resource "aws_iam_role_policy" "oracledb_backup_bucket_access_policy" {
  name   = "${var.env_name}-oracledb-backup-bucket-access-policy"
  role   = aws_iam_role.db_ec2_instance_iam_role.name
  policy = data.aws_iam_policy_document.oracledb_backup_bucket_access.json
}

resource "aws_kms_key" "oracledb_backup_key" {
  description = "kms key for oracle db backup"
}

resource "aws_kms_alias" "oracledb_backup_kms_key_alias" {
  name          = "alias/${lower(local.s3_oracledb_backup_key_alias)}"
  target_key_id = aws_kms_key.oracledb_backup_key.key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_oracledb_backup_bucket_encryption" {
  bucket = module.s3_bucket_oracledb_backups.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.oracledb_backup_key.key_id
      sse_algorithm     = "aws:kms"
    }
  }
}