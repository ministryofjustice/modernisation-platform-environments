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

# Security Group
resource "aws_security_group" "efs" {
  name        = "vcms-${local.environment}-efs"
  description = "Allow traffic between vcms service and efs"
  vpc_id      = local.account_info.vpc_id

  tags = merge(
    local.tags,
    {
      Name = "vcms-efs-${local.environment}"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "efs_ingress_vpc" {
  security_group_id = aws_security_group.efs.id
  description       = "ingress vpc rules"

  type        = "ingress"
  from_port   = 2049
  to_port     = 2049
  protocol    = "tcp"
  cidr_blocks = [local.account_config.shared_vpc_cidr]
}

resource "aws_security_group_rule" "efs_egress_vpc" {
  security_group_id = aws_security_group.efs.id
  description       = "egress vpc rules"

  type        = "egress"
  from_port   = 2049
  to_port     = 2049
  protocol    = "tcp"
  cidr_blocks = [local.account_config.shared_vpc_cidr]
}
