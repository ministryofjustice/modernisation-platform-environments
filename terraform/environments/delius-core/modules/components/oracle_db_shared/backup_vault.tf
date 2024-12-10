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

# Allow the modernisation-platform-oidc-cicd role to assume the
# new role oracle_ec2_backup_service_role which allows us
# to write snapshots to the Backup Vault.   We use Backup Vault
# to manage EC2 snapshots for Oracle hosts as these are only
# created sporadically, e.g. ahead of a service release, and will
# therefore not be continually overwritten.  Writing them to a
# backup vault allows them to timeout without being overwritten.
# The AWSBackupServiceRolePolicyForBackup is managed by AWS and
# is documented at: https://docs.aws.amazon.com/aws-backup/latest/devguide/iam-service-roles.html
resource "aws_iam_policy" "oracle_ec2_snapshot_backup_pass_role_policy" {
  description = "Allow iam:PassRole for oracle_ec2_snapshot_backup_role"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = "arn:aws:iam::${var.account_info.id}:role/service-role/AWSBackupDefaultServiceRole"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "oracle_ec2_snapshot_backup_pass_role_policy_attachment" {
  name       = "oracle-ec2-snapshot-backup-pass-role-policy-attachment"
  roles      = ["modernisation-platform-oidc-cicd"]
  policy_arn = aws_iam_policy.oracle_ec2_snapshot_backup_pass_role_policy.arn
}
