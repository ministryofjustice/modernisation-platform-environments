# module for efs file system

resource "aws_efs_file_system" "vcms" {
  creation_token                  = "vcms-${local.environment}"
  encrypted                       = true
  kms_key_id                      = local.account_config.kms_keys.general_shared
  throughput_mode                 = "bursting"
  provisioned_throughput_in_mibps = null

  tags = local.tags
}

resource "aws_efs_mount_target" "vcms" {
  for_each        = toset(local.account_config.private_subnet_ids)
  file_system_id  = aws_efs_file_system.vcms.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "vcms" {
  file_system_id = aws_efs_file_system.vcms.id
  root_directory {
    path = "/"
  }
  tags = merge(
    local.tags,
    {
      Name = "vcms-${local.environment}-efs-access-point"
    }
  )
}
