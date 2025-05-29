# -------------------------------------------------------
# get glue, s3 ip ranges and define ports
# -------------------------------------------------------

data "aws_ip_ranges" "london_s3" {
  regions  = ["eu-west-2"]
  services = ["s3"]
}

data "aws_ip_ranges" "london_glue" {
  regions  = ["eu-west-2"]
  services = ["glue"]
}

variable "sqlserver_https_ports" {
  description = "List of ports required for Glue outbound connections"
  type        = list(number)
  default     = [1433, 443]
}

# -------------------------------------------------------
# Define groups and rules
# -------------------------------------------------------

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

resource "aws_security_group_rule" "dms_tcp_outbound" {
  for_each          = toset([for port in var.sqlserver_https_ports : tostring(port)])
  security_group_id = aws_security_group.dms_ri_security_group.id
  type              = "egress"
  cidr_blocks       = data.aws_ip_ranges.london_s3.cidr_blocks
  protocol          = "tcp"
  from_port         = each.value
  to_port           = each.value
  description       = "DMS Terraform"
}

resource "aws_vpc_security_group_egress_rule" "dms_db_ob_access" {

  security_group_id            = aws_security_group.dms_ri_security_group.id
  description                  = "dms_rds_db_outbound"
  ip_protocol                  = "tcp"
  from_port                    = 1433
  to_port                      = 1433
  referenced_security_group_id = aws_security_group.db.id
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
# Glue self-referencing rule
# -------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "glue_glue_ingress" {
  security_group_id            = aws_security_group.glue_rds_conn_security_group.id
  referenced_security_group_id = aws_security_group.glue_rds_conn_security_group.id
  ip_protocol                  = "tcp"
  from_port                    = 0
  to_port                      = 65535
  description                  = "Glue         +-----[mssql]----- Glue"
}