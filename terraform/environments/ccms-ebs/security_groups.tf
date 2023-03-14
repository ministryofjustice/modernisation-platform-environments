# Security Group for the baseline EC2
resource "aws_security_group" "ec2_sg_oracle_base" {
  name = "ec2_sg_oracle_base"
  ######## Fix this description, once all rules are matched up in code ########
  description = "Baseline image of Oracle Linux 7.9"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-ec2", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ingress_traffic_oracle_base" {
  for_each          = local.application_data.ec2_sg_base_ingress_rules
  security_group_id = aws_security_group.ec2_sg_oracle_base.id
  type              = "ingress"
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]

}

resource "aws_security_group_rule" "egress_traffic_oracle_base_sg" {
  for_each = local.application_data.ec2_sg_base_egress_rules
  #for_each          = local.application_data.ec2_sg_egress_rules
  security_group_id        = aws_security_group.ec2_sg_oracle_base.id
  type                     = "egress"
  description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol                 = each.value.protocol
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  source_security_group_id = aws_security_group.ec2_sg_oracle_base.id
}
resource "aws_security_group_rule" "egress_traffic_oracle_base_cidr" {
  for_each = local.application_data.ec2_sg_base_egress_rules
  #for_each          = local.application_data.ec2_sg_egress_rules
  security_group_id = aws_security_group.ec2_sg_oracle_base.id
  type              = "egress"
  description       = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [each.value.destination_cidr]
}

# Security Group for EBSDB
resource "aws_security_group" "ec2_sg_ebsdb" {
  name        = "ec2_sg_ebsdb"
  description = "SG traffic control for EBSDB"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-OracleBaseImage", local.application_name, local.environment)) }
  )
}
resource "aws_security_group_rule" "ingress_traffic_ebsdb" {
  for_each          = local.application_data.ec2_sg_ingress_rules
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "ingress"
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [data.aws_vpc.shared.cidr_block, local.application_data.accounts[local.environment].mp_aws_subnet_env]
}
resource "aws_security_group_rule" "egress_traffic_ebsdb_sg" {
  for_each                 = local.application_data.ec2_sg_egress_rules
  security_group_id        = aws_security_group.ec2_sg_ebsdb.id
  type                     = "egress"
  description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol                 = each.value.protocol
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  source_security_group_id = aws_security_group.ec2_sg_ebsdb.id
}
resource "aws_security_group_rule" "egress_traffic_ebsdb_cidr" {
  for_each          = local.application_data.ec2_sg_egress_rules
  security_group_id = aws_security_group.ec2_sg_ebsdb.id
  type              = "egress"
  description       = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [each.value.destination_cidr]
}

# Security Group for EBSAPPS
resource "aws_security_group" "ec2_sg_ebsapps" {
  name        = "ec2_sg_ebsapps"
  description = "SG traffic control for EBSAPPS"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-OracleBaseImage", local.application_name, local.environment)) }
  )
}
resource "aws_security_group_rule" "ingress_traffic_ebsapps" {
  for_each          = local.application_data.ec2_sg_ingress_rules
  security_group_id = aws_security_group.ec2_sg_ebsapps.id
  type              = "ingress"
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [data.aws_vpc.shared.cidr_block, local.application_data.accounts[local.environment].mp_aws_subnet_env]
}
resource "aws_security_group_rule" "egress_traffic_ebsapps_sg" {
  for_each                 = local.application_data.ec2_sg_egress_rules
  security_group_id        = aws_security_group.ec2_sg_ebsapps.id
  type                     = "egress"
  description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol                 = each.value.protocol
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  source_security_group_id = aws_security_group.ec2_sg_ebsapps.id
}
resource "aws_security_group_rule" "egress_traffic_ebsapps_cidr" {
  for_each          = local.application_data.ec2_sg_egress_rules
  security_group_id = aws_security_group.ec2_sg_ebsapps.id
  type              = "egress"
  description       = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [each.value.destination_cidr]
}

# Security Group for WebGate
resource "aws_security_group" "ec2_sg_webgate" {
  name        = "ec2_sg_webgate"
  description = "SG traffic control for WebGate"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-OracleBaseImage", local.application_name, local.environment)) }
  )
}
resource "aws_security_group_rule" "ingress_traffic_webgate" {
  for_each          = local.application_data.ec2_sg_ingress_rules
  security_group_id = aws_security_group.ec2_sg_webgate.id
  type              = "ingress"
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [data.aws_vpc.shared.cidr_block, local.application_data.accounts[local.environment].mp_aws_subnet_env]
}
resource "aws_security_group_rule" "egress_traffic_webgate_sg" {
  for_each                 = local.application_data.ec2_sg_egress_rules
  security_group_id        = aws_security_group.ec2_sg_webgate.id
  type                     = "egress"
  description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol                 = each.value.protocol
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  source_security_group_id = aws_security_group.ec2_sg_webgate.id
}
resource "aws_security_group_rule" "egress_traffic_webgate_cidr" {
  for_each          = local.application_data.ec2_sg_egress_rules
  security_group_id = aws_security_group.ec2_sg_webgate.id
  type              = "egress"
  description       = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [each.value.destination_cidr]
}

# Security Group for AccessGate
resource "aws_security_group" "ec2_sg_accessgate" {
  name        = "ec2_sg_accessgate"
  description = "SG traffic control for AccessGate"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-OracleBaseImage", local.application_name, local.environment)) }
  )
}
resource "aws_security_group_rule" "ingress_traffic_accessgate" {
  for_each          = local.application_data.ec2_sg_ingress_rules
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "ingress"
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [data.aws_vpc.shared.cidr_block, local.application_data.accounts[local.environment].mp_aws_subnet_env]
}
resource "aws_security_group_rule" "egress_traffic_accessgate_sg" {
  for_each                 = local.application_data.ec2_sg_egress_rules
  security_group_id        = aws_security_group.ec2_sg_accessgate.id
  type                     = "egress"
  description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol                 = each.value.protocol
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  source_security_group_id = aws_security_group.ec2_sg_accessgate.id
}
resource "aws_security_group_rule" "egress_traffic_accessgate_cidr" {
  for_each          = local.application_data.ec2_sg_egress_rules
  security_group_id = aws_security_group.ec2_sg_accessgate.id
  type              = "egress"
  description       = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [each.value.destination_cidr]
}


# Security Group for EBSAPP-Loadbalancer
resource "aws_security_group" "sg_ebsapps_lb" {
  name        = "sg_ebsapps_lb"
  description = "Inbound traffic control for EBSAPPS loadbalancer"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "allow all outgoing traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-OracleBaseImage", local.application_name, local.environment)) }
  )
}

# Security Group for FTP Server
resource "aws_security_group" "ec2_sg_ftp" {
  name        = "ec2_sg_ftp"
  description = "Security Group for FTP Server"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-FTP", local.application_name, local.environment)) }
  )
}

# Ingress Traffic FTP
resource "aws_security_group_rule" "ingress_traffic_ftp" {
  for_each          = local.application_data.ec2_sg_ftp_ingress_rules
  security_group_id = aws_security_group.ec2_sg_ftp.id
  type              = "ingress"
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [data.aws_vpc.shared.cidr_block, local.application_data.accounts[local.environment].lz_aws_subnet_env]
}

# Egress Traffic FTP
resource "aws_security_group_rule" "egress_traffic_ftp" {
  for_each          = local.application_data.ec2_sg_ftp_egress_rules
  security_group_id = aws_security_group.ec2_sg_ftp.id
  type              = "egress"
  description       = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [each.value.destination_cidr]
  //  source_security_group_id = aws_security_group.ec2_sg_ftp.id
}


# Rule for all ingress/egress within the environment
resource "aws_security_group_rule" "all_internal_ingress_traffic" {
  for_each          = { for sub in data.aws_security_groups.all_security_groups.ids : sub => sub }
  security_group_id = each.value
  type              = "ingress"
  description       = "Ingress for all internal traffic"
  protocol          = "all"
  from_port         = 0
  to_port           = 0
  cidr_blocks = [
    data.aws_subnet.data_subnets_a.cidr_block,
    data.aws_subnet.data_subnets_b.cidr_block,
    data.aws_subnet.data_subnets_c.cidr_block,
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
  ]
}

resource "aws_security_group_rule" "all_internal_egress_traffic" {
  for_each          = { for sub in data.aws_security_groups.all_security_groups.ids : sub => sub }
  security_group_id = each.value
  #security_group_id = aws_security_group.ec2_sg_oracle_base.id
  type        = "egress"
  description = "Egress for all internal traffic"
  protocol    = "all"
  from_port   = 0
  to_port     = 0
  cidr_blocks = [
    data.aws_subnet.data_subnets_a.cidr_block,
    data.aws_subnet.data_subnets_b.cidr_block,
    data.aws_subnet.data_subnets_c.cidr_block,
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
  ]
}
