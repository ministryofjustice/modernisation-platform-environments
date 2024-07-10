resource "aws_security_group" "dms" {
  vpc_id      = var.account_info.vpc_id
  name        = "${var.env_name}-dms-sg"
  description = "Security group for DMS Replication Instances"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "dms_instance_https_out" {
  security_group_id = aws_security_group.dms.id
  cidr_ipv4         = var.account_config.shared_vpc_cidr
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allow communication out on port 443, e.g. for SSM"
  tags = merge(var.tags,
    { Name = "https-out" }
  )
}

resource "aws_vpc_security_group_egress_rule" "dms_db_conn" {
  security_group_id            = aws_security_group.dms.id
  description                  = "Allow communication between DMS and delius db instances"
  from_port                    = 1521
  to_port                      = 1521
  ip_protocol                  = "tcp"
  cidr_ipv4                    = var.account_config.shared_vpc_cidr
  tags = merge(var.tags,
    { Name = "oracle-out" }
  )
}