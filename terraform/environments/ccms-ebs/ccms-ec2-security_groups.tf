# Rule for all ingress/egress within the environment
resource "aws_security_group_rule" "all_internal_ingress_traffic" {
  for_each          = { for sub in data.aws_security_groups.all_security_groups.ids : sub => sub }
  security_group_id = each.value
  type              = "ingress"
  description       = "All internal traffic"
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
  description = "All internal traffic"
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

#--Disabled until the ingress/egress rules in aws_security_group.lambda_security_group are removed
#--Should be applied immediatley after they are removed

/* resource "aws_security_group_rule" "ingress_oracledb" {
  type              = "ingress"
  from_port         = 1521
  to_port           = 1522
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.lambda_security_group.id
}

#--https://dsdmoj.atlassian.net/browse/CC-3348?atlOrigin=eyJpIjoiYzAzODExNjc3NWIxNDEyNGI4NjM5NDk1NmVkMzI2ZTAiLCJwIjoiaiJ9
#--This should not be left in place, for the purposes of fixing a terraform bug only
#--the existence of this rule is undermining the purpose of all other rules in
#--aws_security_group_rule.all_internal_egress_traffic) -- AW 08/04/25
resource "aws_security_group_rule" "egress_oracledb" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" #--Any
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lambda_security_group.id
} */
