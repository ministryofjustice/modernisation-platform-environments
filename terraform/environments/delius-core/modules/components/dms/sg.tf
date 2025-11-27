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
  from_port                    = local.db_port
  to_port                      = local.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.db_ec2_sg_id
  tags = merge(var.tags,
    { Name = "oracle-out" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "dms_db_conn_in" {
  security_group_id            = aws_security_group.dms.id
  description                  = "Allow incoming communication between delius db instances and DMS"
  from_port                    = local.db_port
  to_port                      = local.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.db_ec2_sg_id
  tags = merge(var.tags,
    { Name = "oracle-in" }
  )
}

resource "aws_vpc_security_group_egress_rule" "db_dms_conn_out" {
  security_group_id            = var.db_ec2_sg_id
  description                  = "Allow outgoing communication between delius db instances and DMS"
  from_port                    = local.db_port
  to_port                      = local.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.dms.id
  tags = merge(var.tags,
    { Name = "dms-out" }
  )
}

resource "aws_vpc_security_group_ingress_rule" "db_dms_conn_in" {
  security_group_id            = var.db_ec2_sg_id
  description                  = "Allow incoming communication between DMS and delius db instances"
  from_port                    = local.db_port
  to_port                      = local.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.dms.id
  tags = merge(var.tags,
    { Name = "dms-in" }
  )
}

resource "aws_vpc_security_group_egress_rule" "dms_s3_conn_out" {
  security_group_id = aws_security_group.dms.id
  description       = "Allow outgoing communication between DMS and VPC S3 endpoint"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_prefix_list.s3.prefix_list_id
  tags = merge(var.tags,
    { Name = "s3-out" }
  )
}
