#module "s3_bucket_oracledb_backups" {
#  source              = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.0.0"
#  bucket_name         = "${var.env_name}-oracle-database-backups"
#  versioning_enabled  = false
#  ownership_controls  = "BucketOwnerEnforced"
#  replication_enabled = false
#  custom_kms_key      = var.account_config.general_shared_kms_key_arn
#
#  providers = {
#    aws.bucket-replication = aws.bucket-replication
#  }
#
#  lifecycle_rule = [
#    {
#      id      = "main"
#      enabled = "Enabled"
#      prefix  = ""
#
#      tags = {
#        rule      = "log"
#        autoclean = "true"
#      }
#
#      transition = [
#        {
#          days          = 90
#          storage_class = "STANDARD_IA"
#        }
#      ]
#
#      expiration = {
#        days = 365
#      }
#    }
#  ]
#
#  tags = local.tags
#}
#
#data "aws_iam_policy_document" "oracledb_backup_bucket_access" {
#  statement {
#    sid    = "allowAccessToOracleDbBackupBucket"
#    effect = "Allow"
#    actions = [
#      "s3:*"
#    ]
#    resources = [
#      "${module.s3_bucket_oracledb_backups.bucket.arn}",
#      "${module.s3_bucket_oracledb_backups.bucket.arn}/*"
#    ]
#  }
#
#  statement {
#    sid    = "AllowAccessToS3OracleBackups"
#    effect = "Allow"
#    actions = [
#      "s3:Get*",
#      "s3:List*"
#    ]
#    resources = [
#      "arn:aws:s3:::eu-west-2-dmd-mis-dev-oracledb-backups",
#      "arn:aws:s3:::eu-west-2-dmd-mis-dev-oracledb-backups/*"
#    ]
#  }
#
#  statement {
#    sid    = "listAllBuckets"
#    effect = "Allow"
#    actions = [
#      "s3:ListAllMyBuckets",
#      "s3:GetBucketLocation"
#    ]
#    resources = [
#      "arn:aws:s3:::*"
#    ]
#  }
#}
#
#resource "aws_iam_role_policy" "oracledb_backup_bucket_access_policy" {
#  name   = "${var.env_name}-oracledb-backup-bucket-access-policy"
#  role   = aws_iam_role.db_ec2_instance_iam_role.name
#  policy = data.aws_iam_policy_document.oracledb_backup_bucket_access.json
#}