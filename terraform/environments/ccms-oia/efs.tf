resource "aws_efs_file_system" "oia-storage" {
  encrypted        = true
  performance_mode = "generalPurpose" # we may want to change to "maxIo"
  # throughput_mode and provisioned_throughput_in_mibps we may want to set (default is bursting)
  tags = merge(local.tags,
    { Name = lower(format("%s-efs", local.application_name)) }
  )
}

resource "aws_efs_mount_target" "oia-mount_A" {
  file_system_id = aws_efs_file_system.oia-storage.id
  subnet_id      = data.aws_subnet.private_subnets_a.id
  security_groups = [
    aws_security_group.oia-efs-security-group.id
  ]
}

resource "aws_efs_mount_target" "oia-mount_B" {
  file_system_id = aws_efs_file_system.oia-storage.id
  subnet_id      = data.aws_subnet.private_subnets_b.id
  security_groups = [
    aws_security_group.oia-efs-security-group.id
  ]
}

resource "aws_efs_mount_target" "oia-mount_C" {
  file_system_id = aws_efs_file_system.oia-storage.id
  subnet_id      = data.aws_subnet.private_subnets_c.id
  security_groups = [
    aws_security_group.oia-efs-security-group.id
  ]
}

resource "aws_security_group" "oia-efs-security-group" {
  name_prefix = "oia-efs-security-group"
  description = "allow inbound access from container instances"
  vpc_id      = data.aws_vpc.shared.id

  // Allow inbound access from container instances
  ingress {
    protocol    = "tcp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
  }

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-efs-sg", local.application_name)) }
  )
}