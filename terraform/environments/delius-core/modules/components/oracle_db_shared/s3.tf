module "s3_bucket_oracledb_backups" {
  source              = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.1.0"
  bucket_name         = "${local.oracle_backup_bucket_name}"
  versioning_enabled  = false
  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false
  custom_kms_key      = var.account_config.kms_keys.general_shared
  bucket_policy = compact([local.oracle_duplicate_delius_target_environment != "" ? templatefile("${path.module}/policies/oracledb_backup_data.json",
    {
      s3bucket_arn                               = module.s3_bucket_oracledb_backups.bucket.arn,
      oracle_duplicate_delius_target_account_id  = local.oracle_duplicate_delius_target_account_id,
      oracle_duplicate_delius_target_environment = local.oracle_duplicate_delius_target_environment
  }) : null])
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

  tags = var.tags
}

data "aws_iam_policy_document" "oracledb_backup_bucket_access" {
  statement {
    sid    = "allowAccessToOracleDbBackupBucket"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "${module.s3_bucket_oracledb_backups.bucket.arn}",
      "${module.s3_bucket_oracledb_backups.bucket.arn}/*"
    ]
  }

  statement {
    sid    = "allowAccessToOracleDbBackupInventoryBucket"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      "${aws_s3_bucket.s3_bucket_oracledb_backups_inventory.arn}",
      "${aws_s3_bucket.s3_bucket_oracledb_backups_inventory.arn}/*"
    ]
  }

  statement {
    sid    = "AllowAccessToLegacyS3OracleBackups"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      "arn:aws:s3:::eu-west-2-${var.environment_config.migration_environment_full_name}-oracledb-backups",
      "arn:aws:s3:::eu-west-2-${var.environment_config.migration_environment_full_name}-oracledb-backups/*"
    ]
  }

  statement {
    sid    = "listAllBuckets"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::*"
    ]
  }

  statement {
    sid    = "allowAccessToOracleStatisticsBucket"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "${module.s3_bucket_oracle_statistics.bucket.arn}",
      "${module.s3_bucket_oracle_statistics.bucket.arn}/*"
    ]
  }

}


data "aws_iam_policy_document" "oracle_remote_statistics_bucket_access" {

  statement {
    sid    = "allowAccessToListOracleStatistics${title(local.oracle_statistics_delius_source_environment)}Bucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = ["arn:aws:s3:::${local.oracle_statistics_delius_source_environment}-oracle-statistics-backup-data"]
  }

  statement {
    sid    = "allowAccessToOracleStatistics${title(local.oracle_statistics_delius_source_environment)}BucketObjects"
    effect = "Allow"
    actions = [
      "s3:PutObjectAcl",
      "s3:PutObject",
      "s3:GetObjectTagging",
      "s3:GetObject"
    ]
    resources = ["arn:aws:s3:::${local.oracle_statistics_delius_source_environment}-oracle-statistics-backup-data/*"]
  }
}

data "aws_iam_policy_document" "oracledb_remote_backup_bucket_access" {

  statement {
    sid    = "allowAccessToOracleDb${title(local.oracle_duplicate_delius_source_environment)}Bucket"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::${local.oracle_backup_bucket_name}",
      "arn:aws:s3:::${local.oracle_backup_bucket_name}/*"
    ]
  }
}

data "aws_iam_policy_document" "combined" {
  source_policy_documents = compact([
    data.aws_iam_policy_document.oracledb_backup_bucket_access.json,
    local.oracle_statistics_delius_source_environment != "" ? data.aws_iam_policy_document.oracle_remote_statistics_bucket_access.json : null,
    local.oracle_duplicate_delius_source_environment != "" ? data.aws_iam_policy_document.oracledb_remote_backup_bucket_access.json : null
  ])
}

resource "aws_iam_policy" "oracledb_backup_bucket_access" {
  name        = "${var.env_name}-oracledb-backup-bucket-access"
  description = "Allow access to Oracle DB Backup Bucket"
  policy      = data.aws_iam_policy_document.combined.json
}

resource "aws_s3_bucket" "s3_bucket_oracledb_backups_inventory" {
  bucket = "${local.oracle_backup_bucket_name}-inventory"
  tags = merge(
    var.tags,
    {
      "Name" = "${local.oracle_backup_bucket_name}-inventory"
    },
    {
      "Purpose" = "Inventory of Oracle DB Backup Pieces"
    },
  )
}


resource "aws_s3_bucket_versioning" "s3_bucket_oracledb_backups_inventory" {
  bucket = aws_s3_bucket.s3_bucket_oracledb_backups_inventory.id
  versioning_configuration {
    status = "Suspended"
  }
}


data "aws_caller_identity" "current" {
}

resource "aws_s3_bucket_public_access_block" "oracledb_backups_inventory" {
  bucket                  = aws_s3_bucket.s3_bucket_oracledb_backups_inventory.id
  block_public_acls       = true # Block public access to buckets and objects granted through *new* access control lists (ACLs)
  ignore_public_acls      = true # Block public access to buckets and objects granted through any access control lists (ACLs)
  block_public_policy     = true # Block public access to buckets and objects granted through new public bucket or access point policies
  restrict_public_buckets = true # Block public and cross-account access to buckets and objects through any public bucket or access point policies
}

resource "aws_s3_bucket_policy" "oracledb_backups_inventory_policy" {
  bucket = aws_s3_bucket.s3_bucket_oracledb_backups_inventory.id
  policy = templatefile("${path.module}/policies/oracledb_backups_inventory.json",
    {
      backup_s3bucket_arn    = module.s3_bucket_oracledb_backups.bucket.arn,
      inventory_s3bucket_arn = aws_s3_bucket.s3_bucket_oracledb_backups_inventory.arn,
      aws_account_id         = data.aws_caller_identity.current.account_id
    }
  )
}

resource "aws_s3_bucket_inventory" "oracledb_backuppieces" {
  bucket = module.s3_bucket_oracledb_backups.bucket.id
  name   = "${var.env_name}-oracle-database-backuppieces"

  included_object_versions = "Current"

  optional_fields = ["Size", "LastModifiedDate"]

  schedule {
    frequency = "Daily"
  }

  destination {
    bucket {
      format     = "CSV"
      bucket_arn = aws_s3_bucket.s3_bucket_oracledb_backups_inventory.arn
    }
  }
}

# Bucket for storing Oracle Statistics Backup Dump Files

module "s3_bucket_oracle_statistics" {
  source              = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.0.0"
  bucket_name         = "delius-mis-${var.env_name}-oracle-statistics-backup-data"
  versioning_enabled  = false
  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false
  custom_kms_key      = var.account_config.kms_keys.general_shared
  bucket_policy = compact([local.oracle_statistics_delius_target_environment != "" ? templatefile("${path.module}/policies/oracle_statistics_backup_data.json",
    {
      s3bucket_arn                                = module.s3_bucket_oracle_statistics.bucket.arn,
      oracle_statistics_delius_target_account_id  = local.oracle_statistics_delius_target_account_id,
      oracle_statistics_delius_target_environment = local.oracle_statistics_delius_target_environment
  }) : null])
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

  tags = var.tags
}
