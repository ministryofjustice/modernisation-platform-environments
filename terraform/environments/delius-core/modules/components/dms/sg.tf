resource "aws_security_group" "dms" {
  vpc_id      = var.account_info.vpc_id
  name        = "${var.env_name}-dms-sg"
  description = "Security group for DMS Replication Instances"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "dms_db_conn_out" {
  security_group_id            = aws_security_group.dms.id
  description                  = "Allow outgoing communication between DMS and delius db instances"
  from_port                    = 1521
  to_port                      = 1521
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.db_ec2_sg_id
  tags = merge(var.tags,
    { Name = "oracle-out" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "dms_db_conn_in" {
  security_group_id            = aws_security_group.dms.id
  description                  = "Allow incoming communication between delius db instances and DMS"
  from_port                    = 1521
  to_port                      = 1521
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.db_ec2_sg_id
  tags = merge(var.tags,
    { Name = "oracle-in" }
  )
}

resource "aws_vpc_security_group_egress_rule" "db_dms_conn_out" {
  security_group_id            = var.db_ec2_sg_id
  description                  = "Allow outgoing communication between delius db instances and DMS"
  from_port                    = 1521
  to_port                      = 1521
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.dms.id
  tags = merge(var.tags,
    { Name = "dms-out" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "db_dms_conn_in" {
  security_group_id            = var.db_ec2_sg_id
  description                  = "Allow incoming communication between DMS and delius db instances"
  from_port                    = 1521
  to_port                      = 1521
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.dms.id
  tags = merge(var.tags,
    { Name = "dms-in" }
  )
}