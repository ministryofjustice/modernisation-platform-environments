resource "aws_efs_file_system" "storage" {
  encrypted        = true
  performance_mode = "generalPurpose" # we may want to change to "maxIo"	
  # throughput_mode and provisioned_throughput_in_mibps we may want to set (default is bursting)	
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-efs", local.application_name, local.environment)) }
  )
}

resource "aws_efs_mount_target" "mount" {
  file_system_id = aws_efs_file_system.storage.id
  subnet_id      = data.aws_subnet.data_subnets_a.id
  security_groups = [
    aws_security_group.efs-security-group.id
  ]
}

resource "aws_efs_mount_target" "mount_B" {
  file_system_id = aws_efs_file_system.storage.id
  subnet_id      = data.aws_subnet.data_subnets_b.id
  security_groups = [
    aws_security_group.efs-security-group.id
  ]
}

resource "aws_efs_mount_target" "mount_C" {
  file_system_id = aws_efs_file_system.storage.id
  subnet_id      = data.aws_subnet.data_subnets_c.id
  security_groups = [
    aws_security_group.efs-security-group.id
  ]
}

resource "aws_security_group" "efs-security-group" {
  name_prefix = "${local.application_name}-efs-security-group"
  description = "allow inbound access from container instances"
  vpc_id      = data.aws_vpc.shared.id
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
  cidr_ipv4 = "0.0.0.0/0" #--Tighen. AW
}

resource "aws_vpc_security_group_ingress_rule" "efs-security-group-ingress" {
  count             = length(local.data_subnets_cidr_blocks)
  description       = "Allow inbound access from container instances"
  security_group_id = aws_security_group.efs-security-group.id
  ip_protocol       = "tcp"
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = local.data_subnets_cidr_blocks[count.index]
}
