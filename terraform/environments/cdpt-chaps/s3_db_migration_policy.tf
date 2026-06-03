locals {
  source_db_identifier                = "db-chaps-dev"
  native_backup_option_group          = "chaps-${local.environment}-sqlserver-native-backup"
  mp_rds_native_backup_role_name      = "chaps-${local.environment}-rds-native-backup"
  cp_db_migration_copy_irsa_role_arn  = "arn:aws:iam::754256621582:role/cloud-platform-irsa-c5c488d70a0c0af2-live"
}

data "aws_iam_policy_document" "rds_native_backup_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:db:${local.source_db_identifier}",
        "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:og:${local.native_backup_option_group}"
      ]
    }
  }
}

resource "aws_iam_role" "rds_native_backup" {
  name               = local.mp_rds_native_backup_role_name
  assume_role_policy = data.aws_iam_policy_document.rds_native_backup_assume_role.json

  tags = local.tags
}

data "aws_iam_policy_document" "rds_native_backup_s3_kms" {
  statement {
    sid = "GetMigrationBucketLocation"

    actions = [
      "s3:GetBucketLocation"
    ]

    resources = [
      aws_s3_bucket.db_migration.arn
    ]
  }

  statement {
    sid = "ListMigrationBucketPrefix"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.db_migration.arn
    ]

    condition {
      test      = "StringLike"
      variable  = "s3:prefix"
      values = [
        local.db_migration_prefix,
        "${local.db_migration_prefix}/",
        "${local.db_migration_prefix}/*"
      ]
    }
  }

  statement {
    sid = "ReadWriteMigrationObjects"

    actions = [
      "s3:GetObject",
      "s3:GetObjectAttributes",
      "s3:PutObject",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload"
    ]

    resources = [
      "${aws_s3_bucket.db_migration.arn}/${local.db_migration_prefix}/*"
    ]
  }

  statement {
    sid = "UseMigrationKmsKeyForBackup"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]

    resources = [
      aws_kms_key.db_migration.arn
    ]
  }
}

resource "aws_iam_policy" "rds_native_backup_s3_kms" {
  name   = "chaps-dev-rds-native-backup-s3-kms"
  policy = data.aws_iam_policy_document.rds_native_backup_s3_kms.json
}

resource "aws_iam_role_policy_attachment" "rds_native_backup_s3_kms" {
  role       = aws_iam_role.rds_native_backup.name
  policy_arn = aws_iam_policy.rds_native_backup_s3_kms.arn
}

data "aws_iam_policy_document" "db_migration_bucket_policy" {
  statement {
    sid = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.db_migration.arn,
      "${aws_s3_bucket.db_migration.arn}/*"
    ]

    condition {
      test = "Bool"
      variable = "aws:SecureTransport"
      values = ["false"]
    }
  }

  statement {
    sid = "AllowCpMigrationCopyRoleToGetBucketLocation"

    principals {
      type        = "AWS"
      identifiers = [local.cp_db_migration_copy_irsa_role_arn]
    }

    actions = [
      "s3:GetBucketLocation"
    ]

    resources = [
      aws_s3_bucket.db_migration.arn
    ]
  }

  statement {
    sid = "AllowCpMigrationCopyRoleToListBackupPrefix"

    principals {
      type = "AWS"
      identifiers = [local.cp_db_migration_copy_irsa_role_arn]
    }

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.db_migration.arn
    ]

    condition {
      test = "StringLike"
      variable = "s3:prefix"
      values = [
        local.db_migration_prefix,
        "${local.db_migration_prefix}/",
        "${local.db_migration_prefix}/*"
      ]
    }
  }

  statement {
    sid = "AllowCpMigrationCopyRoleToReadBackupObjects"

    principals {
      type    = "AWS"
      identifiers = [local.cp_db_migration_copy_irsa_role_arn]
    }

    actions = [
      "s3:GetObject",
      "s3:GetObjectAttributes"
    ]

    resources = [
      "${aws_s3_bucket.db_migration.arn}/${local.db_migration_prefix}/*"
      ]
  }
}

resource "aws_s3_bucket_policy" "db_migration" {
  bucket = aws_s3_bucket.db_migration.id
  policy = data.aws_iam_policy_document.db_migration_bucket_policy.json
}

data "aws_iam_policy_document" "db_migration_kms" {
  statement {
    sid = "allowAccountRoot"
    effect = "Allow"
    actions = ["kms:*"]

    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid = "AllowMpRdsNativeBackupRole"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [aws_iam_role.rds_native_backup.arn]
    }
  }

  statement {
    sid = "AllowCpMigrationCopyRoleToDecrypt"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [local.cp_db_migration_copy_irsa_role_arn]
    }
  }
}

output "db_migration_kms_key_arn" {
  value       = aws_kms_key.db_migration.arn
  description = "KMS key ARN for the CHAPS dev DB migration S3 bucket"
}

output "db_migration_bucket_name" {
  value       = aws_s3_bucket.db_migration.bucket
  description = "S3 bucket containing CHAPS dev DB migration backups"
}
