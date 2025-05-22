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

data "aws_iam_policy_document" "backup_actions_policy_document" {
  statement {
    effect = "Allow"
    actions = ["backup:ListBackupVaults",
      "backup:StartBackupJob",
      "backup:DescribeBackupJob",
      "ec2:DescribeSnapshots"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "backup_actions_policy" {
  name   = "${var.env_name}-backup_actions_policy"
  policy = data.aws_iam_policy_document.backup_actions_policy_document.json
}

resource "aws_iam_role_policy_attachment" "backup_actions_policy_attachment" {
  role       = aws_iam_role.aws_backup_default_service_role[0].name
  policy_arn = aws_iam_policy.backup_actions_policy.arn
}