resource "aws_efs_file_system" "storage" {
  count            = local.is-development || local.is-test ? 1 : 0
  encrypted        = true
  performance_mode = local.application_data.accounts[local.environment].ssogen_efs_performance_mode
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-efs", local.application_name_ssogen, local.environment)) }
  )
}

resource "aws_efs_mount_target" "mount" {
  count          = local.is-development || local.is-test ? 1 : 0
  file_system_id = aws_efs_file_system.storage.id
  subnet_id      = data.aws_subnet.data_subnets_a.id
  security_groups = [
    aws_security_group.efs-security-group.id
  ]
}

resource "aws_efs_mount_target" "mount_B" {
  count          = local.is-development || local.is-test ? 1 : 0
  file_system_id = aws_efs_file_system.storage[count.index].id
  subnet_id      = data.aws_subnet.data_subnets_b.id
  security_groups = [
    aws_security_group.efs-security-group[count.index].id
  ]
}

resource "aws_efs_mount_target" "mount_C" {
   count         = local.is-development || local.is-test ? 1 : 0
  file_system_id = aws_efs_file_system.storage[count.index].id
  subnet_id      = data.aws_subnet.data_subnets_c.id
  security_groups = [
    aws_security_group.efs-security-group[count.index].id
  ]
}
