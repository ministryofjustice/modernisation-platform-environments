data "aws_subnet" "private" {
  id = var.account_config.private_subnet_ids[0]
}

resource "aws_datasync_location_efs" "destination" {
  count = var.ldap_config.efs_datasync_destination_arn != null ? 1 : 0
  ec2_config {
    security_group_arns = [aws_security_group.ldap_efs.arn]
    subnet_arn          = data.aws_subnet.private.arn
  }
  efs_file_system_arn = var.ldap_config.efs_datasync_destination_arn
}

resource "aws_datasync_location_efs" "source" {
  ec2_config {
    security_group_arns = [aws_security_group.ldap_efs.arn]
    subnet_arn          = data.aws_subnet.private.arn
  }
  efs_file_system_arn = aws_efs_file_system.ldap.arn
}

resource "aws_datasync_task" "ldap_refresh_task" {
  count                    = var.ldap_config.efs_datasync_destination_arn != null ? 1 : 0
  destination_location_arn = aws_datasync_location_efs.destination[0].arn
  source_location_arn      = aws_datasync_location_efs.source.arn

  name = "ldap-datasync-task-push-from-${var.env_name}"
}