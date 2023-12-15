module "s3_bucket_oracledb_backups" {
  source              = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.0.0"
  bucket_name         = "${var.env_name}-oracle-database-backups"
  versioning_enabled  = false
  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false
  custom_kms_key      = var.account_config.kms_keys.general_shared

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
    sid    = "AllowAccessToS3OracleBackups"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      "arn:aws:s3:::eu-west-2-dmd-mis-dev-oracledb-backups",
      "arn:aws:s3:::eu-west-2-dmd-mis-dev-oracledb-backups/*"
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
}

resource "aws_iam_role_policy" "oracledb_backup_bucket_access_policy" {
  name   = "${var.env_name}-oracledb-backup-bucket-access-policy"
  role   = aws_iam_role.db_ec2_instance_iam_role.name
  policy = data.aws_iam_policy_document.oracledb_backup_bucket_access.json
}


resource "aws_s3_bucket" "s3_bucket_oracledb_backups_inventory" {
  bucket = "${var.env_name}-oracle-database-backups-inventory"
  tags = merge(
    var.tags,
    {
      "Name" =  "${var.env_name}-oracle-database-backups-inventory"
    },
    {
      "Purpose" = "Inventory of Oracle DB Backup Pieces"
    },
  )
}


resource "aws_s3_bucket_versioning" "s3_bucket_oracledb_backups_inventory" {
  bucket = aws_s3_bucket.s3_bucket_oracledb_backups_inventory.id
  versioning_configuration {
    status = "Enabled"
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

data "template_file" "oracledb_backups_inventory_policy_file" {
  template = templatefile("${path.module}/policies/oracledb_backups_inventory.json",
                            {
                              backup_s3bucket_arn = module.s3_bucket_oracledb_backups.bucket.arn,
                              inventory_s3bucket_arn = aws_s3_bucket.s3_bucket_oracledb_backups_inventory.arn,
                              aws_account_id = data.aws_caller_identity.current.account_id
                            }
                          )
}

resource "aws_s3_bucket_policy" "oracledb_backups_inventory_policy" {
  bucket = aws_s3_bucket.s3_bucket_oracledb_backups_inventory.id
  policy = data.template_file.oracledb_backups_inventory_policy_file.rendered
}

resource "aws_s3_bucket_inventory" "oracledb_backuppieces" {
  bucket = module.s3_bucket_oracledb_backups.bucket.id
  name   = "${var.env_name}-oracle-database-backuppieces"

  included_object_versions = "Current"

  optional_fields = ["Size","LastModifiedDate"]

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