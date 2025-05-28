# -------------------------------------------------------
# get glue, s3 ip ranges
# -------------------------------------------------------

data "aws_ip_ranges" "london_s3" {
  regions  = ["eu-west-2"]
  services = ["s3"]
}

data "aws_ip_ranges" "london_glue" {
  regions  = ["eu-west-2"]
  services = ["glue"]
}

# -------------------------------------------------------
# Security Groups
# -------------------------------------------------------

# Security group for DMS-to-S3 communication
resource "aws_security_group" "dms_to_s3_security_group" {
  name        = "dms-to-s3-security-group"
  description = "Security Group for DMS communication with S3"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    {
      Resource_Type = "DMS to S3 VPC Endpoint Security Group",
    }
  )
}

resource "aws_security_group" "glue_security_group" {
  name        = "glue-security-group"
  description = "Security Group for Glue client"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    {
      Resource_Type = "Glue Security Group",
    }
  )
}

resource "aws_security_group" "rds_security_group" {
  name        = "rds-security-group"
  description = "Security Group for RDS server"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    {
      Resource_Type = "RDS Security Group",
    }
  )
}

# -------------------------------------------------------
# DMS to S3 Security Group Rules
# -------------------------------------------------------

resource "aws_security_group_rule" "dms_to_s3_egress" {
  security_group_id = aws_security_group.dms_to_s3_security_group.id
  type              = "egress"
  cidr_blocks       = data.aws_ip_ranges.london_s3.cidr_blocks
  protocol          = "tcp"
  from_port         = 433
  to_port           = 433
  description       = "Allow DMS to communicate with S3 over HTTPS"
}

# -------------------------------------------------------
# Glue to RDS Security Group Rules - SQL Server communication
# -------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "glue_to_rds_ingress" {
  security_group_id            = aws_security_group.glue_security_group.id
  referenced_security_group_id = aws_security_group.rds_security_group.id
  ip_protocol                  = "tcp"
  from_port                    = 1433
  to_port                      = 1433
  description                  = "Allow incoming traffic *from* RDS *to* Glue on SQL Server port 1433"
}

resource "aws_vpc_security_group_egress_rule" "glue_to_rds_egress" {
  security_group_id            = aws_security_group.glue_security_group.id
  referenced_security_group_id = aws_security_group.rds_security_group.id
  ip_protocol                  = "tcp"
  from_port                    = 1433
  to_port                      = 1433
  description                  = "Allow outgoing traffic *to* Glue *from* RDS on SQL Server port 1433"
}

# -------------------------------------------------------
# RDS to Glue Security Group Rules - HTTPS traffic
# -------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "rds_to_glue_ingress" {
  security_group_id            = aws_security_group.rds_security_group.id
  referenced_security_group_id = aws_security_group.glue_security_group.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "Allow traffic *from* Glue *to* RDS on HTTPS port"
}

resource "aws_vpc_security_group_egress_rule" "rds_to_glue_egress" {
  security_group_id            = aws_security_group.rds_security_group.id
  referenced_security_group_id = aws_security_group.glue_security_group.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "Allow traffic *to* Glue *from* RDS on HTTPS port"
}

# -------------------------------------------------------
# Self-referencing Security Group Rules
# -------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "rds_self_reference" {
  security_group_id = aws_security_group.rds_security_group.id
  referenced_security_group_id = aws_security_group.glue_security_group.id
  ip_protocol       = "tcp"
  from_port         = 0
  to_port           = 65535
  description       = "Allow all outbound traffic within the RDS security group to itself"
}
