# EFS 
resource "aws_efs_file_system" "efs" {
  creation_token = "${local.application_name_short}-${local.environment}-efs"
  encrypted        = true
  kms_key_id       = aws_kms_key.efs.arn

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-efs" }
  )
}

# EFS Access Point
resource "aws_efs_access_point" "ecs" {
  file_system_id = aws_efs_file_system.efs.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/ecs"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "755"
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-efs-access-point" }
  )
}

# Mount Targets
resource "aws_efs_mount_target" "az-a" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = data.aws_subnet.private_subnets_a.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "az-b" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = data.aws_subnet.private_subnets_b.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "az-c" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = data.aws_subnet.private_subnets_c.id
  security_groups = [aws_security_group.efs.id]
}
