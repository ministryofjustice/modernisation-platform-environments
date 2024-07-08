resource "aws_security_group" "dms_ri_security_group" {
  name        = "dms_rep_instance_access_tf"
  description = "Secuity Group having relevant acess for DMS"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    {
      Resource_Type = "DMS Replication Instance Access",
    }
  )
}

resource "aws_vpc_security_group_egress_rule" "dms_all_tcp_outbound" {
  security_group_id = aws_security_group.dms_ri_security_group.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  description = "DMS Terraform"
}

resource "aws_vpc_security_group_ingress_rule" "dms_to_rds_sg_rule" {
  security_group_id = aws_security_group.db.id

  referenced_security_group_id = aws_security_group.dms_ri_security_group.id
  ip_protocol                  = "tcp"
  from_port                    = 1433
  to_port                      = 1433
  description                  = "DMS Terraform"
}

resource "aws_security_group_rule" "allow_glue_athena" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.dms_ri_security_group.id
  source_security_group_id = aws_security_group.dms_ri_security_group.id
  description              = "Allow inbound traffic from DMS replication instance to Glue and Athena endpoints"
}

# ---------------------------------------------------------------------------

resource "aws_security_group" "glue_rds_conn_security_group" {
  name        = "glue-rds-sqlserver-connection-tf"
  description = "Secuity Group for Glue-RDS-Connection"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    {
      Resource_Type = "Secuity Group for Glue-RDS-Connection",
    }
  )
}

resource "aws_vpc_security_group_egress_rule" "glue_rds_conn_outbound" {
  security_group_id = aws_security_group.glue_rds_conn_security_group.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  description = "Required ports open for Glue-RDS-Connection"
}

resource "aws_vpc_security_group_ingress_rule" "glue_rds_conn_inbound" {
  security_group_id = aws_security_group.glue_rds_conn_security_group.id

  referenced_security_group_id = aws_security_group.glue_rds_conn_security_group.id
  ip_protocol                  = "tcp"
  from_port                    = 0
  to_port                      = 65535
  description                  = "Required ports open for Glue-RDS-Connection"
}

resource "aws_vpc_security_group_ingress_rule" "glue_rds_conn_db_inbound" {
  security_group_id = aws_security_group.db.id

  referenced_security_group_id = aws_security_group.glue_rds_conn_security_group.id
  ip_protocol                  = "tcp"
  from_port                    = 1433
  to_port                      = 1433
  description                  = "Required ports open for Glue-RDS-Connection"
}

# ---------------------------------------------------------------------------
