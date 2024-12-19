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

# Allow Access To AWSBackupDefaultServiceRolePolicy and AWSBackupOperatorAccess From EC2 Instance Roles
# These roles allow creation of new AWS EC2 snapshots within the backup vault
resource "aws_iam_policy_attachment" "oracle_ec2_aws_backup_service_role_policy_for_backup_attachment" {
  name       = "oracle-ec2-backup-service-role-policy-for-backup-attachment"
  roles      = var.instance_roles
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_policy_attachment" "oracle_ec2_aws_backup_operator_access_attachment" {
  name       = "oracle-ec2-backup-operator-access-attachment"
  roles      = var.instance_roles
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupOperatorAccess"
}