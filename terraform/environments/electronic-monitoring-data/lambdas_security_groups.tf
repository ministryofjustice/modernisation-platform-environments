# ------------------------------------------------------------------------------------------
# create_athena_external_tables: SG for RDS Access
# ------------------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------------------
# send table to ap
# ------------------------------------------------------------------------------------------


resource "aws_security_group" "lambda_sg_send_table_to_ap" {
  name_prefix = "lambda_sg"
  description = "Security Group for send table to ap Lambda"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id       = data.aws_vpc.shared.id
  service_name = "com.amazonaws.eu-west-1.s3"

  vpc_endpoint_type = "Gateway"

  route_table_ids = data.aws_subnets.private_subnets.ids
}
