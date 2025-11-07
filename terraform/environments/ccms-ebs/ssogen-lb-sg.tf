#########################################
# SSOGEN Internal Load Balancer Security Group
#########################################

resource "aws_security_group" "sg_ssogen_internal_alb" {
  name        = "ssogen_internal_alb"
  description = "Inbound and outbound rules for SSOGEN Internal Load Balancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("sg-ssogen-loadbalancer-internal")) }
  )
}

#########################################
# INGRESS RULES
#########################################

# Allow HTTPS (4443) from AWS Workspaces
resource "aws_vpc_security_group_ingress_rule" "ingress_ssogen_internal_4443_workspaces" {
  security_group_id = aws_security_group.sg_ssogen_internal_alb.id
  description       = "Allow HTTPS (4443) from AWS Workspaces CIDR"
  from_port         = 443
  to_port           = 4443
  ip_protocol       = "tcp"
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
}

#########################################
# EGRESS RULES
#########################################

# Allow outbound HTTPS (4443) only to backend SSOGEN EC2s
resource "aws_vpc_security_group_egress_rule" "egress_ssogen_internal_4443_backend" {
  security_group_id            = aws_security_group.sg_ssogen_internal_alb.id
  description                  = "Allow HTTPS (4443) to backend SSOGEN EC2s"
  from_port                    = 4443
  to_port                      = 4443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ssogen_sg[0].id
}


