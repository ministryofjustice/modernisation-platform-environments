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

