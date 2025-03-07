# Sandbox Security Group

resource "aws_security_group" "ec2_sg_sandbox" {
  name        = "ec2_sg_sandbox"
  description = "SG for Sandbox EC2 instances"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("ec2-sg-%s", local.component_name)) }
  )
}

# INGRESS Rules

resource "aws_vpc_security_group_ingress_rule" "sandbox_ingress" {
  security_group_id = aws_security_group.ec2_sg_sandbox.id
  from_port         = 0
  to_port           = 0
  ip_protocol       = "tcp"
  self              = true
}


# EGRESS Rules

resource "aws_vpc_security_group_egress_rule" "sandbox_egress" {
  security_group_id = aws_security_group.ec2_sg_sandbox.id
  from_port         = 0
  to_port           = 0
  ip_protocol       = "tcp"
  self              = true
}