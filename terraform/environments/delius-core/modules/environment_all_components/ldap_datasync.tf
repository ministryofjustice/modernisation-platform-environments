resource "aws_datasync_location_efs" "destination" {
  count = var.ldap_config.efs_datasync_destination_arn != null ? 1 : 0
  ec2_config {
    security_group_arns = [aws_security_group.ldap_efs.arn]
    subnet_arn          = "arn:aws:ec2:${var.account_info.region}:${var.account_info.id}:subnet/${var.account_config.private_subnet_ids[0]}"
  }
  efs_file_system_arn = var.ldap_config.efs_datasync_destination_arn
}

resource "aws_datasync_location_efs" "source" {
  ec2_config {
    security_group_arns = [aws_security_group.ldap_efs.arn]
    subnet_arn          = "arn:aws:ec2:${var.account_info.region}:${var.account_info.id}:subnet/${var.account_config.private_subnet_ids[0]}"
  }
  efs_file_system_arn = aws_efs_file_system.ldap.arn
}

resource "aws_datasync_task" "ldap_refresh_task" {
  count                    = var.ldap_config.efs_datasync_destination_arn != null ? 1 : 0
  destination_location_arn = aws_datasync_location_efs.destination[0].arn
  source_location_arn      = aws_datasync_location_efs.source.arn

  name = "ldap-datasync-task-push-from-${var.env_name}"
}

# iam role for aws backup to assume in the data-refresh pipeline using the aws backup start-restore-job cmd
resource "aws_iam_role" "ldap_datasync_role" {
  name               = "ldap-data-refresh-role"
  assume_role_policy = data.aws_iam_policy_document.ldap_datasync_role_assume.json
}

data "aws_iam_policy_document" "ldap_datasync_role_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["datasync.amazonaws.com", "backup.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ldap_datasync_role_access" {
  statement {
    effect = "Allow"
    actions = [
      "backup:StartRestoreJob",
      "backup:Get*",
      "backup:List*"
    ]
    resources = ["arn:aws:backup:::*/*"]
  }
}