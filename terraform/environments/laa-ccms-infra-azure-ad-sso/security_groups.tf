# Security Group for EBSDB
resource "aws_security_group" "ec2_sg_ebs_vision_db" {
  name        = "ec2_sg_ebs_vision_db"
  description = "SG traffic control for EBS Vision DB"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-vision", local.application_name, local.environment)) }
  )
}

# Security Group for preclone EBSDB
#resource "aws_security_group" "ec2_sg_ebs_vision_preclone_db" {
#  name        = "ec2_sg_ebs_vision_preclone_db"
#  description = "SG traffic control for preclone EBS Vision DB"
#  vpc_id      = data.aws_vpc.shared.id
#  tags = merge(local.tags,
#    { Name = lower(format("sg-%s-%s-vision-pc", local.application_name, local.environment)) }
#  )
#}

resource "aws_security_group_rule" "ingress_traffic_ebs_vision_db" {
  for_each          = local.application_data.ec2_ebs_vision_db_ingress_rules
  security_group_id = aws_security_group.ec2_sg_ebs_vision_db.id
  type              = "ingress"
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks = [data.aws_vpc.shared.cidr_block, local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env, local.application_data.accounts[local.environment].cp_dev_cidr_range]
}

# ingress for preclone ec2
#resource "aws_security_group_rule" "ingress_traffic_ebs_vision_preclone_db" {
#  for_each          = local.application_data.ec2_ebs_vision_db_ingress_rules
#  security_group_id = aws_security_group.ec2_sg_ebs_vision_preclone_db.id
#  type              = "ingress"
#  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
#  protocol          = each.value.protocol
#  from_port         = each.value.from_port
#  to_port           = each.value.to_port
#  cidr_blocks = [data.aws_vpc.shared.cidr_block, local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env, local.application_data.accounts[local.environment].cp_dev_cidr_range]
#}


resource "aws_security_group_rule" "egress_traffic_ebs_vision_db_sg" {
  for_each                 = local.application_data.ec2_ebs_vision_db_egress_rules
  security_group_id        = aws_security_group.ec2_sg_ebs_vision_db.id
  type                     = "egress"
  description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol                 = each.value.protocol
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  source_security_group_id = aws_security_group.ec2_sg_ebs_vision_db.id
}

//egress for preclone
#resource "aws_security_group_rule" "egress_traffic_ebs_vision_preclone_db_sg" {
#  for_each                 = local.application_data.ec2_ebs_vision_db_egress_rules
#  security_group_id        = aws_security_group.ec2_sg_ebs_vision_preclone_db.id
#  type                     = "egress"
#  description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
#  protocol                 = each.value.protocol
#  from_port                = each.value.from_port
#  to_port                  = each.value.to_port
#  source_security_group_id = aws_security_group.ec2_sg_ebs_vision_preclone_db.id
#}


resource "aws_security_group_rule" "egress_traffic_ebsdb_cidr" {
  for_each          = local.application_data.ec2_ebs_vision_db_egress_rules
  security_group_id = aws_security_group.ec2_sg_ebs_vision_db.id
  type              = "egress"
  description       = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [each.value.destination_cidr]
}

# egress cidr for preclone
#resource "aws_security_group_rule" "egress_traffic_preclone_ebsdb_cidr" {
#  for_each          = local.application_data.ec2_ebs_vision_db_egress_rules
#  security_group_id = aws_security_group.ec2_sg_ebs_vision_preclone_db.id
#  type              = "egress"
#  description       = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
#  protocol          = each.value.protocol
#  from_port         = each.value.from_port
#  to_port           = each.value.to_port
#  cidr_blocks       = [each.value.destination_cidr]
#}

## ------------------------LOAD BALANCER SECURITY GROUP ----------------------------------------------
# Security Group for EBS-APP-Loadbalancer
resource "aws_security_group" "sg_ebs_vision_db_lb" {
  name        = "sg_ebs_vision_db_lb"
  description = "Inbound traffic control for EBS Vision DB loadbalancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-loadbalancer", local.application_name, local.environment)) }
  )
}
//preclone lb security group
#resource "aws_security_group" "sg_ebs_vision_db_preclone_lb" {
#  name        = "sg_ebs_vision_db_preclone_lb"
#  description = "Inbound traffic control for preclone EBS Vision DB loadbalancer"
#  vpc_id      = data.aws_vpc.shared.id
#
#  tags = merge(local.tags,
#    { Name = lower(format("sg-%s-%s-loadbalancer-pc", local.application_name, local.environment)) }
#  )
#}

resource "aws_security_group_rule" "ingress_traffic_lb" {
  for_each          = local.application_data.lb_sg_ingress_rules
  security_group_id = aws_security_group.sg_ebs_vision_db_lb.id
  type              = "ingress"
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [data.aws_vpc.shared.cidr_block, local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env, local.application_data.accounts[local.environment].cp_dev_cidr_range]
}
//ingress for preclone
#resource "aws_security_group_rule" "ingress_traffic_preclone_lb" {
#  for_each          = local.application_data.lb_sg_ingress_rules
#  security_group_id = aws_security_group.sg_ebs_vision_db_preclone_lb.id
#  type              = "ingress"
#  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
#  protocol          = each.value.protocol
#  from_port         = each.value.from_port
#  to_port           = each.value.to_port
#  cidr_blocks       = [data.aws_vpc.shared.cidr_block, local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env, local.application_data.accounts[local.environment].cp_dev_cidr_range]
#}


resource "aws_security_group_rule" "ingress_traffic_lb_to_ebs" {
  for_each                 = local.application_data.lb_sg_ingress_rules
  security_group_id        = aws_security_group.ec2_sg_ebs_vision_db.id
  type                     = "ingress"
  description              = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol                 = each.value.protocol
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  source_security_group_id = aws_security_group.sg_ebs_vision_db_lb.id
}


//ingress for preclone ec2
#resource "aws_security_group_rule" "ingress_traffic_preclone_lb_to_ebs" {
#  for_each                 = local.application_data.lb_sg_ingress_rules
#  security_group_id        = aws_security_group.ec2_sg_ebs_vision_preclone_db.id
#  type                     = "ingress"
#  description              = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
#  protocol                 = each.value.protocol
#  from_port                = each.value.from_port
#  to_port                  = each.value.to_port
#  source_security_group_id = aws_security_group.ec2_sg_ebs_vision_preclone_db.id
#}

resource "aws_security_group_rule" "egress_traffic_ebslb_sg" {
  for_each                 = local.application_data.lb_sg_egress_rules
  security_group_id        = aws_security_group.sg_ebs_vision_db_lb.id
  type                     = "egress"
  description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol                 = each.value.protocol
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  source_security_group_id = aws_security_group.ec2_sg_ebs_vision_db.id
}

//egress cidr for preclone lb
#resource "aws_security_group_rule" "egress_traffic_preclone_ebslb_sg" {
#  for_each                 = local.application_data.lb_sg_egress_rules
#  security_group_id        = aws_security_group.sg_ebs_vision_db_preclone_lb.id
#  type                     = "egress"
#  description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
#  protocol                 = each.value.protocol
#  from_port                = each.value.from_port
#  to_port                  = each.value.to_port
#  source_security_group_id = aws_security_group.sg_ebs_vision_db_preclone_lb.id
#}

resource "aws_security_group_rule" "egress_traffic_ebslb_cidr" {
  for_each          = local.application_data.lb_sg_egress_rules
  security_group_id = aws_security_group.sg_ebs_vision_db_lb.id
  type              = "egress"
  description       = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [each.value.destination_cidr]
}
//egress cidr for preclone lb
#resource "aws_security_group_rule" "egress_traffic_preclone_ebslb_cidr" {
#  for_each          = local.application_data.lb_sg_egress_rules
#  security_group_id = aws_security_group.sg_ebs_vision_db_preclone_lb.id
#  type              = "egress"
#  description       = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
#  protocol          = each.value.protocol
#  from_port         = each.value.from_port
#  to_port           = each.value.to_port
#  cidr_blocks       = [each.value.destination_cidr]
#}

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
  type              = "egress"
  description       = "Egress for all internal traffic"
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


