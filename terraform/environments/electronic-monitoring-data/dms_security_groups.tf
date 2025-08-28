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
  count       = local.is-production || local.is-development ? 1 : 0
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
  for_each          = local.is-production || local.is-development ? toset([for port in var.sqlserver_https_ports : tostring(port)]) : toset([])
  security_group_id = aws_security_group.dms_ri_security_group[0].id
  type              = "egress"
  cidr_blocks       = data.aws_ip_ranges.london_s3.cidr_blocks
  protocol          = "tcp"
  from_port         = each.value
  to_port           = each.value
  description       = "DMS Terraform"
}

resource "aws_vpc_security_group_egress_rule" "dms_db_ob_access" {
  count                        = local.is-production || local.is-development ? 1 : 0
  security_group_id            = aws_security_group.dms_ri_security_group[0].id
  description                  = "dms_rds_db_outbound"
  ip_protocol                  = "tcp"
  from_port                    = 1433
  to_port                      = 1433
  referenced_security_group_id = aws_security_group.db[0].id
}

resource "aws_vpc_security_group_ingress_rule" "dms_to_rds_sg_rule" {
  count             = local.is-production || local.is-development ? 1 : 0
  security_group_id = aws_security_group.db[0].id

  referenced_security_group_id = aws_security_group.dms_ri_security_group[0].id
  ip_protocol                  = "tcp"
  from_port                    = 1433
  to_port                      = 1433
  description                  = "DMS Terraform"
}

resource "aws_security_group_rule" "allow_glue_athena" {
  count                    = local.is-production || local.is-development ? 1 : 0
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.dms_ri_security_group[0].id
  source_security_group_id = aws_security_group.dms_ri_security_group[0].id
  description              = "Allow inbound traffic from DMS replication instance to Glue and Athena endpoints"
}
