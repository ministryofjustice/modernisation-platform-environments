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

      "kms:Encrypt",
      "kms:Decrypt",
    ]
    resources = [var.account_config.kms_keys.general_shared]
  }
}

