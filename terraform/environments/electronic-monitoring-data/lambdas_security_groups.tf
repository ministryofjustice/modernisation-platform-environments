# ------------------------------------------------------------------------------------------
# create_athena_external_tables: SG for RDS Access
# ------------------------------------------------------------------------------------------add
resource "aws_security_group" "lambda_db_security_group" {
  name        = "lambda_db_instance_sg"
  description = "Security Group allowing lambda access to RDS"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_egress_rule" "lambda_all_outbound" {
  security_group_id = aws_security_group.lambda_db_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 0
  to_port           = 65535
  description       = "Lambda outbound access"
}

resource "aws_vpc_security_group_ingress_rule" "lambda_to_rds_sg_rule" {
  security_group_id = aws_security_group.db.id

  referenced_security_group_id = aws_security_group.lambda_db_security_group.id
  ip_protocol                  = "tcp"
  from_port                    = 1433
  to_port                      = 1433
  description                  = "Lambda RDS Access"
}
