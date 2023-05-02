# Security Group for EBSDB
resource "aws_security_group" "ec2_sg_ebs_vision_db" {
  name        = "ec2_sg_ebs_vision_db"
  description = "SG traffic control for EBS Vision DB"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-vision", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ingress_traffic_ebs_vision_db" {
  for_each          = local.application_data.ec2_ebs_vision_db_ingress_rules
  security_group_id = aws_security_group.ec2_sg_ebs_vision_db.id
  type              = "ingress"
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  # do we add ingress for cloud platform as well
  cidr_blocks = [data.aws_vpc.shared.cidr_block]
}

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
resource "aws_security_group_rule" "ingress_traffic_lb" {
  for_each          = local.application_data.lb_sg_ingress_rules
  security_group_id = aws_security_group.sg_ebs_vision_db_lb.id
  type              = "ingress"
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

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

