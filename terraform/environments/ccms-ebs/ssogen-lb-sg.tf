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
resource "aws_security_group_rule" "ingress_ssogen_internal_4443_workspaces" {
  security_group_id = aws_security_group.sg_ssogen_internal_alb.id
  type              = "ingress"
  description       = "Allow HTTPS (4443) from AWS Workspaces CIDR"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod]
}


#########################################
# EGRESS RULES
#########################################

# Allow outbound HTTPS (4443) to backend EC2s within VPC
resource "aws_security_group_rule" "egress_ssogen_internal_4443" {
  security_group_id = aws_security_group.sg_ssogen_internal_alb.id
  type              = "egress"
  description       = "Allow outbound HTTPS (4443) to backend targets in VPC"
  protocol          = "tcp"
  from_port         = 4443
  to_port           = 4443
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

#########################################
# NOTES
#########################################
# - This SG is attached to the SSOGEN internal ALB (aws_lb.ssogen_alb)
# - ALB Listener runs on port 4443 with HTTPS
# - Backend instances listen on 4443 using self-signed certs
# - No public exposure (internal-only ALB and private subnets)
# - Access limited to trusted internal CIDRs only
#########################################
