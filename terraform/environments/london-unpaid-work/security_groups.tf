resource "aws_security_group" "london_unpaid_work_alb" {
  name        = "london-unpaid-work-alb"
  description = "London Unpaid Work application load balancer security group"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    {
      Name = "london-unpaid-work-alb"
    },
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "lb_http_self" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.london_unpaid_work_alb.id
  description       = "Allow ALB traffic from itself on HTTP"
}

resource "aws_security_group_rule" "lb_https_self" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.london_unpaid_work_alb.id
  description       = "Allow ALB traffic from itself on HTTPS"
}

resource "aws_security_group_rule" "lb_bastion_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.london_unpaid_work_alb.id
  description       = "Allow bastion access to the ALB on HTTP"
  cidr_blocks = [
    "10.161.98.0/28",
    "10.161.98.16/28",
    "10.161.98.32/28",
  ]
}

resource "aws_security_group_rule" "lb_bastion_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.london_unpaid_work_alb.id
  description       = "Allow bastion access to the ALB on HTTPS"
  cidr_blocks = [
    "10.161.98.0/28",
    "10.161.98.16/28",
    "10.161.98.32/28",
  ]
}

# The legacy repo also allowed MOJ VPN / ARK access and Route53 health checker CIDRs.
# Add the matching CIDR blocks from the legacy environment when they are available.
# For example:
# resource "aws_security_group_rule" "lb_admin_https" {
#   type              = "ingress"
#   from_port         = 443
#   to_port           = 443
#   protocol          = "tcp"
#   security_group_id = aws_security_group.london_unpaid_work_alb.id
#   description       = "MOJ VPN and ARK https"
#   cidr_blocks       = ["PLACEHOLDER_CR_ANCILLARY_ADMIN_CIDR"]
# }
