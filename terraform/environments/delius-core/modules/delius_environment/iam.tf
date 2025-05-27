# Only create one role per account
resource "aws_iam_role" "aws_backup_default_service_role" {
  count = contains(["poc", "stage"], var.env_name) ? 0 : 1
  name  = "AWSBackupDefaultServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "backup.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  count      = contains(["poc", "stage"], var.env_name) ? 0 : 1
  role       = aws_iam_role.aws_backup_default_service_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore_policy" {
  count      = contains(["poc", "stage"], var.env_name) ? 0 : 1
  role       = aws_iam_role.aws_backup_default_service_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}
