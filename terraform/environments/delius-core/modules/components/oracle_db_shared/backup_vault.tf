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

resource "aws_backup_vault_policy" "oracle_backup_vault_policy" {
  backup_vault_name = aws_backup_vault.oracle_backup_vault.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement: [
      {
        Sid: "AllowRoleAccess",
        Effect: "Allow",
        Principal: {
          AWS: "${aws_iam_role.oracle_ec2_snapshot_backup_role.arn}"
        },
        Action: [
          "backup:StartBackupJob",
          "backup:StopBackupJob",
          "backup:StartRestoreJob",
          "backup:DeleteBackup",
          "backup:ListBackupJobs",
          "backup:GetBackupVaultAccessPolicy",
          "backup:PutBackupVaultAccessPolicy"
        ],
        Resource: "${aws_backup_vault.oracle_backup_vault.arn}"
      }
    ]
  })
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

# New IAM role to allow writing of AWS EC2 snapshots of Oracle Hosts to Backup Vault
resource "aws_iam_role" "oracle_ec2_snapshot_backup_role" {
  name = "oracle-ec2-snapshot-backup-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "ForAnyValue:ArnLike": {
          "aws:PrincipalArn": "arn:aws:iam::${var.account_info.id}:role/modernisation-platform-oidc-cicd"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "oracle_ec2_snapshot_backup_role_policy_attachment" {
  role       = aws_iam_role.oracle_ec2_snapshot_backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "oracle_ec2_snapshot_backup_operator_policy_attachment" {
  role       = aws_iam_role.oracle_ec2_snapshot_backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupOperatorAccess"
}

resource "aws_iam_policy" "oracle_ec2_snapshot_backup_pass_role_policy" {
  description = "Allow iam:PassRole for oracle_ec2_snapshot_backup_role"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = aws_iam_role.oracle_ec2_snapshot_backup_role.arn
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "oracle_ec2_snapshot_backup_pass_role_policy_attachment" {
  name       = "oracle-ec2-snapshot-backup-pass-role-policy-attachment"
  roles      = ["modernisation-platform-oidc-cicd"]
  policy_arn = aws_iam_policy.oracle_ec2_snapshot_backup_pass_role_policy.arn
}
