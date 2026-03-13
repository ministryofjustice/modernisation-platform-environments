#trivy:ignore:AVD-AWS-0345
data "aws_iam_policy_document" "s3_bucket_oracledb_immutable_backups" {
  #checkov:skip=CKV_AWS_108 "ignore"
  #checkov:skip=CKV_AWS_111 "ignore"
  #checkov:skip=CKV_AWS_356 "ignore"
  count   = lookup(local.oracle_duplicate_map[var.env_name], "target_account_id", false) != false ? 1 : 0
  version = "2012-10-17"

  statement {
    sid     = "OracleBackupAccess"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      module.s3_bucket_oracledb_immutable_backups.bucket.arn,
      "${module.s3_bucket_oracledb_immutable_backups.bucket.arn}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.oracle_duplicate_map[var.env_name]["target_account_id"]}:role/instance-role-${var.account_info.application_name}-${local.oracle_duplicate_map[var.env_name]["target_environment"]}-${var.db_suffix}-1"]
    }
  }

}

module "s3_bucket_oracledb_immutable_backups" {
  #checkov:skip=CKV_TF_1 "ignore"
  source              = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v9.0.0"
  bucket_name         = local.oracle_immutable_backup_bucket_prefix
  versioning_enabled  = true
  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false
  custom_kms_key      = var.account_config.kms_keys.general_shared
  bucket_policy = try([data.aws_iam_policy_document.s3_bucket_oracledb_immutable_backups[0].json], [
    "{}"
  ])

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
        days = local.oracle_backup_bucket_expiration
      }
    }
  ]

  tags = var.tags
}


resource "aws_s3_bucket_inventory" "oracledb_immutable_backup_pieces" {

  bucket = module.s3_bucket_oracledb_immutable_backups.bucket.id
  name   = "${var.account_info.application_name}-${var.env_name}-oracle-${var.db_suffix}-immutable-backup-pieces"

  included_object_versions = "Current"

  optional_fields = ["Size", "LastModifiedDate"]

  schedule {
    frequency = "Daily"
  }

  destination {
    bucket {
      format     = "CSV"
      bucket_arn = module.s3_bucket_oracledb_backups_inventory.bucket.arn
    }
  }
}