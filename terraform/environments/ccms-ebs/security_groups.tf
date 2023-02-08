# Security Group for the baseline EC2
resource "aws_security_group" "ec2_sg_oracle_base" {
  name        = "ec2_sg_oracle_base"
  description = "Baseline image of Oracle Linux 7.9"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-OracleBaseImage", local.application_name, local.environment)) }
  )
}
resource "aws_security_group_rule" "ingress_traffic_oracle_base" {
  for_each          = local.application_data.ec2_sg_ingress_rules
  security_group_id = aws_security_group.ec2_sg_oracle_base.id
  type              = "ingress"
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [data.aws_vpc.shared.cidr_block, "0.0.0.0/0"]
}
resource "aws_security_group_rule" "egress_traffic_oracle_base_sg" {
  for_each                 = local.application_data.ec2_sg_egress_rules
  security_group_id        = aws_security_group.ec2_sg_oracle_base.id
  type                     = "egress"
  description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol                 = each.value.protocol
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  source_security_group_id = aws_security_group.ec2_sg_oracle_base.id
}
resource "aws_security_group_rule" "egress_traffic_oracle_base_cidr" {
  for_each          = local.application_data.ec2_sg_egress_rules
  security_group_id = aws_security_group.ec2_sg_oracle_base.id
  type              = "egress"
  description       = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [each.value.destination_cidr]
}


# Security Group for the EBSDB
resource "aws_security_group" "ec2_sg_ebsdb" {
  name        = "ec2_sg_ebsdb"
  description = "Baseline image of Oracle Linux 7.9"
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
  cidr_blocks       = [data.aws_vpc.shared.cidr_block, "0.0.0.0/0"]
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

# Security Group for the EBSAPPS
resource "aws_security_group" "ec2_sg_ebsapps" {
  name        = "ec2_sg_ebsapps"
  description = "Baseline image of Oracle Linux 7.9"
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
  cidr_blocks       = [data.aws_vpc.shared.cidr_block, "0.0.0.0/0"]
}
resource "aws_security_group_rule" "egress_traffic_ebsapps_sg" {
  for_each                  = local.application_data.ec2_sg_egress_rules
  security_group_id         = aws_security_group.ec2_sg_ebsapps.id
  type                      = "egress"
  description               = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol                  = each.value.protocol
  from_port                 = each.value.from_port
  to_port                   = each.value.to_port
  source_security_group_id  = aws_security_group.ec2_sg_ebsapps.id
}
resource "aws_security_group_rule" "egress_traffic_ebsapps_cidr" {
  for_each                  = local.application_data.ec2_sg_egress_rules
  security_group_id         = aws_security_group.ec2_sg_ebsapps.id
  type                      = "egress"
  description               = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol                  = each.value.protocol
  from_port                 = each.value.from_port
  to_port                   = each.value.to_port
  cidr_blocks               = [each.value.destination_cidr]
}

# Security Group for the WebGate
resource "aws_security_group" "ec2_sg_webgate" {
  name        = "ec2_sg_webgate"
  description = "Baseline image of Oracle Linux 7.9"
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
  cidr_blocks       = [data.aws_vpc.shared.cidr_block, "0.0.0.0/0"]
}
resource "aws_security_group_rule" "egress_traffic_webgate_sg" {
  for_each                  = local.application_data.ec2_sg_egress_rules
  security_group_id         = aws_security_group.ec2_sg_webgate.id
  type                      = "egress"
  description               = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol                  = each.value.protocol
  from_port                 = each.value.from_port
  to_port                   = each.value.to_port
  source_security_group_id  = aws_security_group.ec2_sg_webgate.id
}
resource "aws_security_group_rule" "egress_traffic_webgate_cidr" {
  for_each                  = local.application_data.ec2_sg_egress_rules
  security_group_id         = aws_security_group.ec2_sg_webgate.id
  type                      = "egress"
  description               = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol                  = each.value.protocol
  from_port                 = each.value.from_port
  to_port                   = each.value.to_port
  cidr_blocks               = [each.value.destination_cidr]
}

# Security Group for the AccessGate
resource "aws_security_group" "ec2_sg_accessgate" {
  name        = "ec2_sg_accessgate"
  description = "Baseline image of Oracle Linux 7.9"
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
  cidr_blocks       = [data.aws_vpc.shared.cidr_block, "0.0.0.0/0"]
}
resource "aws_security_group_rule" "egress_traffic_accessgate_sg" {
  for_each                  = local.application_data.ec2_sg_egress_rules
  security_group_id         = aws_security_group.ec2_sg_accessgate.id
  type                      = "egress"
  description               = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol                  = each.value.protocol
  from_port                 = each.value.from_port
  to_port                   = each.value.to_port
  source_security_group_id  = aws_security_group.ec2_sg_accessgate.id
}
resource "aws_security_group_rule" "egress_traffic_accessgate_cidr" {
  for_each                  = local.application_data.ec2_sg_egress_rules
  security_group_id         = aws_security_group.ec2_sg_accessgate.id
  type                      = "egress"
  description               = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol                  = each.value.protocol
  from_port                 = each.value.from_port
  to_port                   = each.value.to_port
  cidr_blocks               = [each.value.destination_cidr]
}