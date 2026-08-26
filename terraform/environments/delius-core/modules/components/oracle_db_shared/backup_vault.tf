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
#
# Note Separation of Roles:
#    The instance role starts the backup so must have StartBackupJob privileges.
#    It must also have privileges to pass the AWSBackupDefaultServiceRole to the Backup Service.
#
data "aws_iam_policy_document" "oracle_ec2_snapshot_backup_role_policy_document" {
  #checkov:skip=CKV_AWS_356 "ignore"
  #checkov:skip=CKV_AWS_111 "ignore"
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${var.account_info.id}:role/AWSBackupDefaultServiceRole"]
  }
  statement {
    sid    = "BackupOperations"
    effect = "Allow"
    actions = [
      "backup:StartBackupJob",
      "backup:ListBackupVaults",
      "backup:DescribeBackupJob",
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes",
      "ec2:CreateSnapshot",
      "ec2:DescribeSnapshots",
      "ec2:CreateTags"
    ]
    resources = ["*"]
  }
}
