# Security Group for EBSDB NLB
resource "aws_security_group" "sg_ebsdb_nlb" {
  name        = "sg_ebsdb_nlb"
  description = "Inbound traffic control for EBSDB network loadbalancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("sg-%s-db-nlb", local.application_name)) }
  )
}

# INGRESS Rules

### HTTPS

resource "aws_security_group_rule" "ingress_traffic_ebsdbnlb" {
  security_group_id = aws_security_group.sg_ebsdb_nlb.id
  type              = "ingress"
  description       = "HTTPS Traffic from MP, CP, LZ Workspaces"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [data.aws_vpc.shared.cidr_block, local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod, local.application_data.accounts[local.environment].cloud_platform_subnet]
}

# EGRESS Rules

### All

resource "aws_security_group_rule" "egress_traffic_ebsdbnlb" {
  security_group_id = aws_security_group.sg_ebsdb_nlb.id
  type              = "egress"
  description       = "All"
  protocol          = "TCP"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}





