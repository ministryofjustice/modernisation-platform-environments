resource "aws_efs_file_system" "appshare" {
  encrypted        = true
  kms_key_id       = data.aws_kms_key.ebs_shared.key_id
  performance_mode = "maxIO"
  throughput_mode  = "bursting"

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(local.tags,
    { Name = "appshare" }
  )
}

resource "aws_efs_mount_target" "mount_a" {
  file_system_id = aws_efs_file_system.appshare.id
  subnet_id      = data.aws_subnet.data_subnets_a.id
  security_groups = [
    aws_security_group.efs-security-group.id
  ]
}

resource "aws_efs_mount_target" "mount_b" {
  file_system_id = aws_efs_file_system.appshare.id
  subnet_id      = data.aws_subnet.data_subnets_b.id
  security_groups = [
    aws_security_group.efs-security-group.id
  ]
}

resource "aws_efs_mount_target" "mount_c" {
  file_system_id = aws_efs_file_system.appshare.id
  subnet_id      = data.aws_subnet.data_subnets_c.id
  security_groups = [
    aws_security_group.efs-security-group.id
  ]
}

resource "aws_security_group" "efs-security-group" {
  name_prefix = "efs-security-group"
  description = "allow inbound access from ebsdb and ebsconc"
  vpc_id      = data.aws_vpc.shared.id

  #  # Allow inbound access from container instances
  #  ingress {
  #    protocol  = "tcp"
  #    from_port = 2049
  #    to_port   = 2049
  #    cidr_blocks = [
  #      data.aws_subnet.data_subnets_a.cidr_block,
  #      data.aws_subnet.data_subnets_b.cidr_block,
  #      data.aws_subnet.data_subnets_c.cidr_block,
  #    ]
  #  }
  #
  #  egress {
  #    protocol  = "-1"
  #    from_port = 0
  #    to_port   = 0
  #    cidr_blocks = [
  #      "0.0.0.0/0",
  #    ]
  #  }

  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-efs", local.application_name, local.environment)) }
  )
}

resource "aws_vpc_security_group_egress_rule" "efs-security-group-egress" {
  description       = "Allow outgoing traffic"
  security_group_id = aws_security_group.efs-security-group.id
  ip_protocol       = "-1"
  # from_port         = 0
  # to_port           = 0
  cidr_ipv4 = "0.0.0.0/0"

  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-efs", local.application_name, local.environment)) }
  )
}

resource "aws_vpc_security_group_ingress_rule" "efs-security-group-ingress" {
  count             = length(local.data_subnets_cidr_blocks)
  description       = "Allow inbound access from container instances"
  security_group_id = aws_security_group.efs-security-group.id
  ip_protocol       = "tcp"
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = local.data_subnets_cidr_blocks[count.index]

  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-efs", local.application_name, local.environment)) }
  )
}
