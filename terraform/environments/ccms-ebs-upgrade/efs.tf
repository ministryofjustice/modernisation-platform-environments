resource "aws_efs_file_system" "appshare" {
  encrypted        = true
  throughput_mode  = "bursting"
  performance_mode = "maxIO"
  tags = merge(local.tags,
    { Name = "appshare" }
  )
}

resource "aws_efs_mount_target" "mount_a" {
  file_system_id = aws_efs_file_system.appshare.id
  subnet_id      = data.aws_subnet.data_subnets_a.id
}

resource "aws_efs_mount_target" "mount_b" {
  file_system_id = aws_efs_file_system.appshare.id
  subnet_id      = data.aws_subnet.data_subnets_b.id
}

resource "aws_efs_mount_target" "mount_c" {
  file_system_id = aws_efs_file_system.appshare.id
  subnet_id      = data.aws_subnet.data_subnets_c.id
}