resource "aws_efs_file_system" "efs" {
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"


  tags = merge(
    local.tags,
    { "Name" = "mp-${local.application_name}-efs" },
    local.environment != "production" ? { "snapshot-with-daily-35-day-retention" = "yes" } : { "snapshot-with-hourly-35-day-retention" = "yes" }
  )
}

resource "aws_security_group" "efs_product" {
  name        = "${local.application_name}-${local.environment}-efs-security-group"
  description = "Apex Product EFS Security Group"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_egress_rule" "efs_product_outbound" {
  security_group_id = aws_security_group.efs_product.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "efs_product_inbound" {
  security_group_id            = aws_security_group.efs_product.id
  description                  = "EFS Rule inbound for instance"
  referenced_security_group_id = aws_security_group.ec2.id
  from_port                    = 2049
  ip_protocol                  = "tcp"
  to_port                      = 2049
}

resource "aws_efs_mount_target" "efs_mount" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = data.aws_subnet.private_subnets_a.id
  security_groups = [aws_security_group.efs_product.id]
}
