resource "aws_efs_file_system" "storage" {
  encrypted        = true
  performance_mode = "generalPurpose" # we may want to change to "maxIo"	
  # throughput_mode and provisioned_throughput_in_mibps we may want to set (default is bursting)	
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-efs", local.application_name, local.environment)) }
  )
}

resource "aws_efs_mount_target" "mount" {
  file_system_id = aws_efs_file_system.storage.id
  subnet_id      = data.aws_subnet.data_subnets_a.id
  security_groups = [
    aws_security_group.efs-security-group.id
  ]
}

resource "aws_efs_mount_target" "mount_B" {
  file_system_id = aws_efs_file_system.storage.id
  subnet_id      = data.aws_subnet.data_subnets_b.id
  security_groups = [
    aws_security_group.efs-security-group.id
  ]
}

resource "aws_efs_mount_target" "mount_C" {
  file_system_id = aws_efs_file_system.storage.id
  subnet_id      = data.aws_subnet.data_subnets_c.id
  security_groups = [
    aws_security_group.efs-security-group.id
  ]
}
