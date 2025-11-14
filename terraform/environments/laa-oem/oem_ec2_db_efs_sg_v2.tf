resource "aws_security_group" "oem_db_efs_sg" {
  name_prefix = "${local.application_name}-db-efs-sg-"
  description = "Allow inbound access from instances"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(tomap(
    { "Name" = "${local.application_name}-db-efs-sg" }
  ), local.tags)

  lifecycle {
    create_before_destroy = true
  }
}

#resource "aws_vpc_security_group_egress_rule" "oem_db_efs_sg_egress_all_0_0_cidr" {
#  security_group_id = aws_security_group.oem_db_efs_sg.id
#  description       = "Allow all outbound traffic"
#  ip_protocol       = "-1"
#  cidr_ipv4         = "0.0.0.0/0"
#
#  tags = {
#    Name = "Allow all outbound traffic"
#  }
#}
#
#resource "aws_vpc_security_group_ingress_rule" "oem_db_efs_sg_ingress_tcp_2049_2049_cidr" {
#  security_group_id = aws_security_group.oem_db_efs_sg.id
#  description       = "NFS access from shared VPC for EFS mount"
#  ip_protocol       = "tcp"
#  from_port         = 2049
#  to_port           = 2049
#  cidr_ipv4         = data.aws_vpc.shared.cidr_block
#
#  tags = {
#    Name = "NFS from shared VPC"
#  }
#}
