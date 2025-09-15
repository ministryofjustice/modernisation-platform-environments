# Security Group for EBSDB NLB
resource "aws_security_group" "sg_ebsdb_nlb" {
  name        = "sg_ebsdb_nlb"
  description = "Inbound traffic control for EBSDB network loadbalancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("sg-%s-db-nlb", local.application_name)) }
  )
}

### INGRESS
# HTTPS
resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdbnlb_1" {
  security_group_id = aws_security_group.sg_ebsdb_nlb.id
  description       = "HTTPS Traffic from MP, CP, LZ Workspaces"
  ip_protocol       = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdbnlb_2" {
  security_group_id = aws_security_group.sg_ebsdb_nlb.id
  description       = "HTTPS Traffic from MP, CP, LZ Workspaces"
  ip_protocol       = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
}

resource "aws_vpc_security_group_ingress_rule" "ingress_traffic_ebsdbnlb_3" {
  security_group_id = aws_security_group.sg_ebsdb_nlb.id
  description       = "HTTPS Traffic from MP, CP, LZ Workspaces"
  ip_protocol       = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = local.application_data.accounts[local.environment].cloud_platform_subnet
}

### EGRESS
# All
resource "aws_vpc_security_group_egress_rule" "egress_traffic_ebsdbnlb" {
  security_group_id = aws_security_group.sg_ebsdb_nlb.id
  description       = "All"
  ip_protocol       = "TCP"
  from_port         = 0
  to_port           = 0
  cidr_ipv4         = ["0.0.0.0/0"]
}
