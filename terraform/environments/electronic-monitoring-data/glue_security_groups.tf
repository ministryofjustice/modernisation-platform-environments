# ---------------------------------------------------------------------------

resource "aws_security_group" "glue_rds_conn_security_group" {
  #checkov:skip=CKV2_AWS_5
  name        = "glue-rds-sqlserver-connection-tf"
  description = "Secuity Group for Glue-RDS-Connection"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    {
      Resource_Type = "Security Group for Glue-RDS-Connection",
    }
  )
}

# -------------------------------------------------------
# Glue-RDS & RDS-Glue Security Group Rules
# -------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "glue_rds_egress" {

  security_group_id            = aws_security_group.glue_rds_conn_security_group.id
  referenced_security_group_id = aws_security_group.db.id
  ip_protocol                  = "tcp"
  from_port                    = 1433
  to_port                      = 1433
  description                  = "Glue          -----[mssql]-----+ RDS Database"
}

resource "aws_vpc_security_group_ingress_rule" "rds_glue_ingress" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = aws_security_group.glue_rds_conn_security_group.id
  ip_protocol                  = "tcp"
  from_port                    = 1433
  to_port                      = 1433
  description                  = "RDS Database +-----[mssql]----- Glue"
}

# -------------------------------------------------------
# Glue-S3 & S3-Glue Security Group Rules
# -------------------------------------------------------

resource "aws_security_group_rule" "glue_s3_egress" {
  for_each          = toset([for port in var.sqlserver_https_ports : tostring(port)])
  security_group_id = aws_security_group.glue_rds_conn_security_group.id
  type              = "egress"
  cidr_blocks       = data.aws_ip_ranges.london_s3.cidr_blocks
  protocol          = "tcp"
  from_port         = each.value
  to_port           = each.value
  description       = "Glue          -----[https+443/1443]-----+ S3 endpoints"
}

# -------------------------------------------------------
# Glue self-referencing rules
# -------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "glue_ingress_all" {
    # Checkov:skip=CKV_AWS_24
    # Checkov:skip=CKV_AWS_25
    # Checkov:skip=CKV_AWS_260
  security_group_id            = aws_security_group.glue_rds_conn_security_group.id
  referenced_security_group_id = aws_security_group.glue_rds_conn_security_group.id
  ip_protocol                  = "tcp"
  from_port                    = 0
  to_port                      = 65535
  description                  = "Glue         +-----[mssql]----- Glue"
}

resource "aws_vpc_security_group_egress_rule" "glue_egress_all" {
  security_group_id            = aws_security_group.glue_rds_conn_security_group.id
  referenced_security_group_id = aws_security_group.glue_rds_conn_security_group.id
  ip_protocol                  = "tcp"
  from_port                    = 0
  to_port                      = 65535
  description                  = "Glue         -----[mssql]----+ Glue"
}