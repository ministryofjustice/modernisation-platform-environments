module "s3_bucket_oracledb_backups" {
  count               = contains(var.components_to_exclude, "db") ? 0 : 1
  source              = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.0.0"
  bucket_name         = "${var.env_name}-oracle-database-backups"
  versioning_enabled  = false
  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false
  custom_kms_key      = var.account_config.general_shared_kms_key_arn

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
  count = contains(var.components_to_exclude, "db") ? 0 : 1
  statement {
    sid    = "allowAccessToOracleDbBackupBucket"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "${module.s3_bucket_oracledb_backups[0].bucket.arn}",
      "${module.s3_bucket_oracledb_backups[0].bucket.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "oracledb_backup_bucket_access_policy" {
  count  = contains(var.components_to_exclude, "db") ? 0 : 1
  name   = "${var.env_name}-oracledb-backup-bucket-access-policy"
  role   = aws_iam_role.db_ec2_instance_iam_role[0].name
  policy = data.aws_iam_policy_document.oracledb_backup_bucket_access[0].json
}
