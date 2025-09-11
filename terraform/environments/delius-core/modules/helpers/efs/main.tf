# module for efs file system

resource "aws_efs_file_system" "this" {
  creation_token                  = var.creation_token
  encrypted                       = var.encrypted
  kms_key_id                      = var.kms_key_arn
  throughput_mode                 = var.throughput_mode
  provisioned_throughput_in_mibps = var.provisioned_throughput_in_mibps

  tags = merge(
    var.tags,
    { Name = "${var.account_info.application_name}-${var.env_name}-${var.name}" },
    var.enable_platform_backups != null ? { "backup" = var.enable_platform_backups ? "true" : "false" } : {}
  )
}

# module for mount target
resource "aws_efs_mount_target" "this" {
  for_each        = toset(var.subnet_ids)
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [aws_security_group.default.id]
}

# module for efs access point
resource "aws_efs_access_point" "this" {
  file_system_id = aws_efs_file_system.this.id
  root_directory {
    path = "/"
  }
  tags = merge(
    var.tags,
    {
      Name = "${var.account_info.application_name}-${var.env_name}-efs-access-point"
    }
  )
}

moved {
  from = aws_efs_access_point.ldap
  to   = aws_efs_access_point.this
}

# Security Group
resource "aws_security_group" "default" {
  name        = "${var.env_name}-${var.name}-efs"
  description = "Allow traffic between ${var.name} service and efs in ${var.env_name}"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-efs-${var.env_name}"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "efs_ingress_vpc" {
  security_group_id = aws_security_group.default.id
  description       = "ingress vpc rules in ${var.env_name}"

  type        = "ingress"
  from_port   = 2049
  to_port     = 2049
  protocol    = "tcp"
  cidr_blocks = [var.vpc_cidr]
}

resource "aws_security_group_rule" "efs_egress_vpc" {
  security_group_id = aws_security_group.default.id
  description       = "egress vpc rules in ${var.env_name}"

  type        = "egress"
  from_port   = 2049
  to_port     = 2049
  protocol    = "tcp"
  cidr_blocks = [var.vpc_cidr]
}
