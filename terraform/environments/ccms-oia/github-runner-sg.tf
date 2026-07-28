# Security Group for GitHub Runner Server
resource "aws_security_group" "ec2_sg_gh_runner" {
  name        = "ec2_sg_clamav"
  description = "Security Group for GitHub Runner Server"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("clamav-%s-sg", local.environment)) }
  )
}

# INGRESS Rules

### Don't think it needs any ingress rules as it doesn't need to be accessed

# EGRESS Rules

resource "aws_security_group_rule" "gh_runner_egress_vpce" {
  security_group_id = aws_security_group.ec2_sg_gh_runner.id
  type              = "egress"
  description       = "Allow egress to protected subnets for VPC endpoints"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks = [
    data.aws_subnet.vpce_subnets_a.cidr_block,
    data.aws_subnet.vpce_subnets_b.cidr_block,
    data.aws_subnet.vpce_subnets_c.cidr_block,
  ]
}

resource "aws_security_group_rule" "gh_runner_egress_443" {
  security_group_id = aws_security_group.ec2_sg_gh_runner.id
  type              = "egress"
  description       = "HTTPS"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks = [
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
  ]
}

resource "aws_security_group_rule" "gh_runner_egress_to_specific_ip" {
  security_group_id = aws_security_group.ec2_sg_gh_runner.id
  type              = "egress"
  description       = "Allow HTTPS to specific IP"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["20.85.130.105/32"]
}