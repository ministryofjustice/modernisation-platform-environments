# Security Group for EBSAPP LB
resource "aws_security_group" "sg_ebsapps_lb" {
  name        = "sg_ebsapps_lb"
  description = "Inbound traffic control for EBSAPPS loadbalancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-loadbalancer", local.application_name, local.environment)) }
  )
}

### INGRESS Rules
# HTTPS
resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebslb_443" {
  security_group_id = aws_security_group.sg_ebsapps_lb.id
  description       = "HTTPS"
  ip_protocol       = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

### EGRESS
# All
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ebslb_80" {
  security_group_id = aws_security_group.ec2_sg_ebsapps.id
  description       = "All"
  ip_protocol       = "TCP"
  from_port         = 0
  to_port           = 0
  cidr_ipv4         = "0.0.0.0/0"
}
