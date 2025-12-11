# Security Group for EBSAPP LB
resource "aws_security_group" "sg_ebsapps_internal_alb" {
  name        = "ebs_apps_internal_alb"
  description = "Inbound traffic control for EBSAPPS Internal loadbalancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("sg-ebsapps-loadbalancer-internal")) }
  )
}

# INGRESS Rules

### HTTPS

resource "aws_security_group_rule" "ingress_traffic_ebsalb_internal_443_workspaces" {
  security_group_id = aws_security_group.sg_ebsapps_internal_alb.id
  type              = "ingress"
  description       = "HTTPS from LZ AWS Workspaces"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod]
}

resource "aws_security_group_rule" "ingress_traffic_ebsalb_internal_443_mojo_devices" {
  security_group_id = aws_security_group.sg_ebsapps_internal_alb.id
  type              = "ingress"
  description       = "HTTPS from Mojo Devices"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [local.application_data.accounts[local.environment].mojo_devices]
}

resource "aws_security_group_rule" "ingress_traffic_ebsalb_internal_443_dom1_devices" {
  security_group_id = aws_security_group.sg_ebsapps_internal_alb.id
  type              = "ingress"
  description       = "HTTPS from Dom1 Devices"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [local.application_data.accounts[local.environment].dom1_devices]
}

# EGRESS Rules

### All

resource "aws_security_group_rule" "egress_traffic_ebsalb_internal_all" {
  security_group_id = aws_security_group.sg_ebsapps_internal_alb.id
  type              = "egress"
  description       = "All"
  protocol          = "TCP"
  from_port         = 8000
  to_port           = 8005
  cidr_blocks       = ["0.0.0.0/0"]
}





