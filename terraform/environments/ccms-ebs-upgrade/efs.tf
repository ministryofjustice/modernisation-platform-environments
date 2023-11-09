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

  # Allow inbound access from container instances	
  ingress {
    protocol  = "tcp"
    from_port = 2049
    to_port   = 2049
    cidr_blocks = [
      data.aws_subnet.data_subnets_a.cidr_block,
      data.aws_subnet.data_subnets_b.cidr_block,
      data.aws_subnet.data_subnets_c.cidr_block,
    ]
  }

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-efs", local.application_name, local.environment)) }
  )
}
