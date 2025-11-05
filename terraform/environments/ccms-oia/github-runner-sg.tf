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

resource "aws_vpc_security_group_egress_rule" "egress_traffic_gh_runner_443" {
  security_group_id = aws_security_group.ec2_sg_gh_runner.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"
}