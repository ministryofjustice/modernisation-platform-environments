data "aws_iam_policy_document" "s3_bucket_oracledb_backups" {
  count   = lookup(local.oracle_duplicate_map[var.env_name], "target_account_id", false) != false ? 1 : 0
  version = "2012-10-17"

  statement {
    sid     = "OracleBackupAccess"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      "${module.s3_bucket_oracledb_backups.bucket.arn}",
      "${module.s3_bucket_oracledb_backups.bucket.arn}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.oracle_duplicate_map[var.env_name]["target_account_id"]}:role/instance-role-${var.account_info.application_name}-${local.oracle_duplicate_map[var.env_name]["target_environment"]}-${var.db_suffix}-1"]
    }
  }

}

module "s3_bucket_oracledb_backups" {
  source              = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.1.0"
  bucket_name         = local.oracle_backup_bucket_prefix
  versioning_enabled  = false
  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false
  custom_kms_key      = var.account_config.kms_keys.general_shared
  bucket_policy = try([data.aws_iam_policy_document.s3_bucket_oracledb_backups[0].json], [
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

  dynamic "statement" {
    for_each = var.deploy_oracle_stats == true ? [1] : []
    content {
      sid    = "allowAccessToOracleStatisticsBucket"
      effect = "Allow"
      actions = [
        "s3:*"
      ]
      resources = [
        "${module.s3_bucket_oracle_statistics[0].bucket.arn}",
        "${module.s3_bucket_oracle_statistics[0].bucket.arn}/*"
      ]
    }
  }

}


data "aws_iam_policy_document" "oracle_remote_statistics_bucket_access" {
  count = lookup(local.oracle_statistics_map[var.env_name], "source_id", null) != null ? 1 : 0
  statement {
    sid    = "allowAccessToListOracleStatistics${title(local.oracle_statistics_map[var.env_name]["source_environment"])}Bucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = ["arn:aws:s3:::${var.account_info.application_name}-${local.oracle_statistics_map[var.env_name]["source_environment"]}-oracle-${var.db_suffix}-statistics-backup-data"]
  }

  statement {
    sid    = "allowAccessToOracleStatistics${title(local.oracle_statistics_map[var.env_name]["source_environment"])}BucketObjects"
    effect = "Allow"
    actions = [
      "s3:PutObjectAcl",
      "s3:PutObject",
      "s3:GetObjectTagging",
      "s3:GetObject"
    ]
    resources = ["arn:aws:s3:::${var.account_info.application_name}-${local.oracle_statistics_map[var.env_name]["source_environment"]}-oracle-${var.db_suffix}-statistics-backup-data/*"]
  }
}

data "aws_iam_policy_document" "oracledb_remote_backup_bucket_access" {
  count = lookup(local.oracle_statistics_map[var.env_name], "source_id", null) != null ? 1 : 0
  statement {
    sid    = "allowAccessToOracleDb${title(local.oracle_statistics_map[var.env_name]["source_environment"])}Bucket"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::${local.oracle_backup_bucket_prefix}",
      "arn:aws:s3:::${local.oracle_backup_bucket_prefix}/*"
    ]
  }
}

data "aws_iam_policy_document" "combined" {
  source_policy_documents = compact([
    try(data.aws_iam_policy_document.oracledb_backup_bucket_access.json, null),
    try(data.aws_iam_policy_document.oracle_remote_statistics_bucket_access[0].json, null),
    try(data.aws_iam_policy_document.oracledb_remote_backup_bucket_access[0].json, null)
  ])
}

resource "aws_iam_policy" "oracledb_backup_bucket_access" {

  name        = "${var.env_name}-oracle-${var.db_suffix}-backup-bucket-access"
  description = "Allow access to Oracle DB Backup Bucket"
  policy      = data.aws_iam_policy_document.combined.json
}

resource "aws_s3_bucket" "s3_bucket_oracledb_backups_inventory" {

  bucket = "${local.oracle_backup_bucket_prefix}-inventory"
  tags = merge(
    var.tags,
    {
      "Name" = "${local.oracle_backup_bucket_prefix}-inventory"
    },
    {
      "Purpose" = "Inventory of Oracle DB Backup Pieces"
    },
  )
}


# encrypting s3 bucket with our shared key (trivy scan)
resource "aws_s3_bucket_server_side_encryption_configuration" "oracledb_backups_inventory" {
  bucket = aws_s3_bucket.s3_bucket_oracledb_backups_inventory.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.account_config.kms_keys.general_shared
      sse_algorithm     = "aws:kms"
    }
  }
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

data "aws_iam_policy_document" "oracledb_backups_inventory" {
  version = "2012-10-17"

  statement {
    sid       = "InventoryPolicy"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.s3_bucket_oracledb_backups_inventory.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = ["${var.account_info.id}"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["${module.s3_bucket_oracledb_backups.bucket.arn}"]
    }

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}


resource "aws_s3_bucket_policy" "oracledb_backups_inventory_policy" {

  bucket = aws_s3_bucket.s3_bucket_oracledb_backups_inventory.id
  policy = data.aws_iam_policy_document.oracledb_backups_inventory.json
}

resource "aws_s3_bucket_inventory" "oracledb_backup_pieces" {

  bucket = module.s3_bucket_oracledb_backups.bucket.id
  name   = "${var.account_info.application_name}-${var.env_name}-oracle-${var.db_suffix}-backup-pieces"

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

data "aws_iam_policy_document" "s3_bucket_oracle_statistics" {
  count   = (lookup(local.oracle_statistics_map[var.env_name], "target_account_id", null) != null) && var.deploy_oracle_stats ? 1 : 0
  version = "2012-10-17"

  statement {
    sid       = "OracleStatisticsListPolicy"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["${module.s3_bucket_oracle_statistics[0].bucket.arn}"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.oracle_statistics_map[var.env_name]["target_account_id"]}:role/instance-role-${var.account_info.application_name}-${local.oracle_statistics_map[var.env_name]["target_environment"]}-${var.db_suffix}-1"]
    }
  }

  statement {
    sid    = "OracleStatisticsObjectPolicy"
    effect = "Allow"
    actions = [
      "s3:PutObjectAcl",
      "s3:PutObject",
      "s3:GetObjectTagging",
      "s3:GetObject"
    ]
    resources = ["${module.s3_bucket_oracle_statistics[0].bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.oracle_statistics_map[var.env_name]["target_account_id"]}:role/instance-role-${var.account_info.application_name}-${local.oracle_statistics_map[var.env_name]["target_environment"]}-${var.db_suffix}-1"]
    }
  }
}


module "s3_bucket_oracle_statistics" {
  count = var.deploy_oracle_stats ? 1 : 0

  source              = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.0.0"
  bucket_name         = "${var.account_info.application_name}-${var.env_name}-oracle-${var.db_suffix}-statistics-backup-data"
  versioning_enabled  = false
  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false
  custom_kms_key      = var.account_config.kms_keys.general_shared
  bucket_policy = try([data.aws_iam_policy_document.s3_bucket_oracle_statistics[0].json], [
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
        days = 365
      }
    }
  ]

  tags = var.tags
}
