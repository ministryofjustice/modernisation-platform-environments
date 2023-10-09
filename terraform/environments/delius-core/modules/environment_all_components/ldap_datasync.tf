data "aws_efs_file_system" "ldap_efs_datasync" {
  for_each = toset(var.environments_in_account)
  tags = {
    Name = "ldap-efs-${each.key}"
  }
}

data "aws_security_group" "ldap_efs_datasync" {
  for_each = toset(var.environments_in_account)
  tags = {
    Name = "ldap-efs-${each.key}"
  }
}

resource "aws_datasync_location_efs" "ldap" {
  for_each = toset(var.environments_in_account)
  efs_file_system_arn = data.aws_efs_file_system.ldap_efs_datasync[each.key].arn

  ec2_config {
    security_group_arns = data.aws_security_group.ldap_efs_datasync[each.key].arn
    subnet_arn          = var.account_config.private_subnet_ids[0]
  }
  tags = var.tags
}

resource "aws_datasync_task" "ldap_efs_high_to_low" {
  destination_location_arn = aws_datasync_location_efs.ldap["test"].arn
  name                     = "example"
  source_location_arn      = aws_datasync_location_efs.ldap["dev"].arn

  options {
    bytes_per_second = -1
  }
}