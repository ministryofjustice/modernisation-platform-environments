# Shared /u01 and /stage filesystems, mounted by ebsapps-1, ebsapps-2 and ebsdb.

resource "aws_efs_file_system" "ebsapps_u01" {
  encrypted  = true
  kms_key_id = data.aws_kms_key.ebs_shared.arn

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-ebsapps-u01"
  })
}

resource "aws_efs_mount_target" "ebsapps_u01" {
  count           = 2
  file_system_id  = aws_efs_file_system.ebsapps_u01.id
  subnet_id       = local.private_subnets[count.index]
  security_groups = [aws_security_group.ebsapps_efs.id]
}

resource "aws_efs_file_system" "ebsapps_stage" {
  encrypted  = true
  kms_key_id = data.aws_kms_key.ebs_shared.arn

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-ebsapps-stage"
  })
}

resource "aws_efs_mount_target" "ebsapps_stage" {
  count           = 2
  file_system_id  = aws_efs_file_system.ebsapps_stage.id
  subnet_id       = local.private_subnets[count.index]
  security_groups = [aws_security_group.ebsapps_efs.id]
}
