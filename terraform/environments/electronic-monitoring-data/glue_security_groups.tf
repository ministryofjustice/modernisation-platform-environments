# ------------------------------------------------------------------------------------------
# create_athena_external_tables: SG for RDS Access
# ------------------------------------------------------------------------------------------add
resource "aws_security_group" "glue_db_security_group" {
  name        = "glue_db_instance_sg"
  description = "Security Group allowing glue access to RDS"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_egress_rule" "glue_all_outbound" {
  security_group_id = aws_security_group.glue_db_security_group.id
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  description = "glue outbound access"
}

resource "aws_vpc_security_group_ingress_rule" "glue_to_rds_sg_rule" {
  security_group_id = aws_security_group.db.id

  referenced_security_group_id = aws_security_group.glue_db_security_group.id
  ip_protocol                  = "tcp"
  from_port                    = 1433
  to_port                      = 1433
  description                  = "glue RDS Access"
}
