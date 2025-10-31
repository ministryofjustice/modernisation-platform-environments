# Security Group for EBSAPP LB
resource "aws_security_group" "sg_ebsapps_lb" {
  name        = "sg_ebsapps_lb"
  description = "Inbound traffic control for EBSAPPS loadbalancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-loadbalancer", local.application_name, local.environment)) }
  )
}

# INGRESS Rules

### HTTPS

resource "aws_security_group_rule" "ingress_traffic_ebslb_443" {
  security_group_id = aws_security_group.sg_ebsapps_lb.id
  type              = "ingress"
  description       = "HTTPS"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}


# EGRESS Rules

### All

resource "aws_security_group_rule" "egress_traffic_ebslb_80" {
  security_group_id = aws_security_group.ec2_sg_ebsapps.id
  type              = "egress"
  description       = "All"
  protocol          = "TCP"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}





