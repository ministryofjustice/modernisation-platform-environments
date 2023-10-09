data "aws_efs_file_system" "ldap_efs_datasync" {
  for_each = toset(var.environments_in_account)
  tags = {
    Name = "ldap-efs-${each.value}"
  }
}

data "aws_security_group" "ldap_efs_datasync" {
  for_each = toset(var.environments_in_account)
  tags = {
    Name = "ldap-efs-${each.value}"
  }
}

output "ldap_efs_datasync_security_group_arns" {
  value = [for sg in data.aws_security_group.ldap_efs_datasync : sg.arn]
}

output "ldap_efs_datasync_file_system_arns" {
  value = [for fs in data.aws_efs_file_system.ldap_efs_datasync : fs.arn]
}

#
#resource "aws_datasync_location_efs" "ldap" {
#  for_each = toset(var.environments_in_account)
#  efs_file_system_arn = data.aws_efs_file_system.ldap_efs_datasync[each.value].arn
#
#  ec2_config {
#    security_group_arns = data.aws_security_group.ldap_efs_datasync[each.value].arn
#    subnet_arn          = var.account_config.private_subnet_ids[0]
#  }
#  tags = var.tags
#}
#
#resource "aws_datasync_task" "ldap_efs_high_to_low" {
#  destination_location_arn = aws_datasync_location_efs.ldap[var.environments_in_account[0]].arn
#  name                     = "example"
#  source_location_arn      = aws_datasync_location_efs.ldap[var.environments_in_account[1]].arn
#
#  options {
#    bytes_per_second = -1
#  }
#}