# Security Group for GitHub Runner Server
resource "aws_security_group" "ec2_sg_gh_runner" {
  name        = "${local.component_name}-${local.env_label}-gh-runner-sg"
  description = "Security Group for GitHub Runner Server"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = "${local.component_name}-${local.env_label}-gh-runner-sg" }
  )
}

# INGRESS Rules - None

# EGRESS Rules

resource "aws_vpc_security_group_egress_rule" "egress_traffic_gh_runner_443" {
  security_group_id = aws_security_group.ec2_sg_gh_runner.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "Allow outbound HTTPS traffic"
}
