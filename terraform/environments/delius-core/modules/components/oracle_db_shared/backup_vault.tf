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
resource "aws_iam_policy" "oracle_ec2_snapshot_backup_role_policy" {
  name = "${var.env_name}-${var.db_suffix}-oracle-ec2-snapshot-backup-role-policy"
  description = "Allow iam:PassRole for AWSBackupDefaultServiceRole"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = "arn:aws:iam::${var.account_info.id}:role/service-role/AWSBackupDefaultServiceRole"
      },
      {
        Effect  = "Allow"
        Action  = ["backup:ListBackupVaults",
                   "backup:StartBackupJob",
                   "backup:DescribeBackupJob",
                   "ec2:DescribeSnapshots"],
        Resource = "*"
      }
    ]
  })
}

# Allow Access To AWSBackupDefaultServiceRolePolicy From EC2 Instance Roles
resource "aws_iam_policy_attachment" "oracle_ec2_snapshot_backup_role_policy_attachment" {
  name       = "${var.env_name}-${var.db_suffix}-ec2-snapshot-backup-role-policy-attach"
  roles      = var.instance_roles
  policy_arn = aws_iam_policy.oracle_ec2_snapshot_backup_role_policy.arn
}