resource "aws_efs_file_system" "oem_app_efs" {
  encrypted        = true
  kms_key_id       = data.aws_kms_key.ebs_shared.arn
  performance_mode = "generalPurpose"
  tags = merge(tomap({
    "Name"                 = "${local.application_name}-app-efs"
    "volume-attach-host"   = "app",
    "volume-attach-device" = "efs://",
    "volume-mount-path"    = "/opt/oem/backups"
  }), local.tags)
}

resource "aws_efs_mount_target" "oem_app_efs" {
  file_system_id = aws_efs_file_system.oem_app_efs.id
  subnet_id      = data.aws_subnet.data_subnets_a.id
  security_groups = [
    aws_security_group.oem_app_efs_sg.id
  ]
}

resource "aws_efs_backup_policy" "policy" {
  file_system_id = aws_efs_file_system.oem_app_efs.id

  backup_policy {
    status = "ENABLED"
  }
}