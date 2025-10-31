# Security Group for EBSAPP LB

resource "aws_security_group" "sg_ebsapps_lb" {
  name        = "lb_sg_sandbox"
  description = "Inbound traffic control for Sandbox EBSAPPS loadbalancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("lb-sg-%s", local.component_name)) }
  )
}

# INGRESS Rules

resource "aws_vpc_security_group_ingress_rule" "sandbox_lb_ingress_workspace" {
  security_group_id = aws_security_group.sg_ebsapps_lb.id
  from_port         = 443
  to_port           = 443
  description       = "HTTPS from LZ AWS Workspace"
  ip_protocol       = "tcp"
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env
}


# EGRESS Rules

resource "aws_vpc_security_group_egress_rule" "sandbox_lb_egress" {
  security_group_id = aws_security_group.sg_ebsapps_lb.id
  from_port         = 0
  to_port           = 65535
  description       = "All"
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}
