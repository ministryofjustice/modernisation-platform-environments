# Shared /u01, /u03 and /stage filesystems for the EBS apps tier, mounted by bothebsapps-1 and ebsapps-2.

resource "aws_efs_file_system" "ebsapps_u01" {
  encrypted  = true
  kms_key_id = data.aws_kms_key.ebs_shared.key_id

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

resource "aws_efs_file_system" "ebsapps_u03" {
  encrypted  = true
  kms_key_id = data.aws_kms_key.ebs_shared.key_id

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-ebsapps-u03"
  })
}

resource "aws_efs_mount_target" "ebsapps_u03" {
  count           = 2
  file_system_id  = aws_efs_file_system.ebsapps_u03.id
  subnet_id       = local.private_subnets[count.index]
  security_groups = [aws_security_group.ebsapps_efs.id]
}

resource "aws_efs_file_system" "ebsapps_stage" {
  encrypted  = true
  kms_key_id = data.aws_kms_key.ebs_shared.key_id

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
