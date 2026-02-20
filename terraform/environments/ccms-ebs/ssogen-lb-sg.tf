#########################################
# SSOGEN Internal Load Balancer Security Group
#########################################

resource "aws_security_group" "sg_ssogen_internal_alb" {
  count       = local.is-development || local.is-test ? 1 : 0
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

# Allow HTTPS from AWS Workspaces
resource "aws_vpc_security_group_ingress_rule" "ingress_ssogen_internal_app_workspaces" {
  count             = local.is-development || local.is-test ? 1 : 0
  security_group_id = aws_security_group.sg_ssogen_internal_alb[count.index].id
  description       = "Allow HTTPS (443) from AWS Workspaces CIDR"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
}

# Allow 5443 from AWS Workspaces
resource "aws_vpc_security_group_ingress_rule" "ingress_ssogen_internal_admin_workspaces" {
  count             = local.is-development || local.is-test ? 1 : 0
  security_group_id = aws_security_group.sg_ssogen_internal_alb[count.index].id
  description       = "Allow HTTPS (5443) from AWS Workspaces CIDR"
  from_port         = 5443
  to_port           = 5443
  ip_protocol       = "tcp"
  cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
}

resource "aws_security_group_rule" "ingress_traffic_ssogenalb_internal_443_mojo_devices" {
  count             = local.is-development || local.is-test ? 1 : 0
  security_group_id = aws_security_group.sg_ssogen_internal_alb[count.index].id
  type              = "ingress"
  description       = "HTTPS from Mojo Devices"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [local.application_data.accounts[local.environment].mojo_devices]
}

resource "aws_security_group_rule" "ingress_traffic_ssogenalb_internal_443_moj_wifi" {
  count             = local.is-development || local.is-test ? 1 : 0
  security_group_id = aws_security_group.sg_ssogen_internal_alb[count.index].id
  type              = "ingress"
  description       = "HTTPS from MoJ WiFi"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [local.application_data.accounts[local.environment].moj_wifi]
}

resource "aws_security_group_rule" "ingress_traffic_ssogenalb_internal_443_dom1_devices" {
  count             = local.is-development || local.is-test ? 1 : 0
  security_group_id = aws_security_group.sg_ssogen_internal_alb[count.index].id
  type              = "ingress"
  description       = "HTTPS from Dom1 Devices"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [local.application_data.accounts[local.environment].dom1_devices]
}

# Allow HTTPS from AWS Workspaces
# resource "aws_vpc_security_group_ingress_rule" "ingress_ssogen_internal_7001_workspaces" {
#   count             = local.is-development || local.is-test ? 1 : 0
#   security_group_id = aws_security_group.sg_ssogen_internal_alb[count.index].id
#   description       = "Allow HTTPS (7001) from AWS Workspaces CIDR"
#   from_port         = 7001
#   to_port           = 7001
#   ip_protocol       = "tcp"
#   cidr_ipv4         = local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
# }
#########################################
# EGRESS RULES
#########################################

# Allow outbound HTTPS (4443) only to backend SSOGEN EC2s
resource "aws_vpc_security_group_egress_rule" "egress_ssogen_internal_app_backend" {
  count                        = local.is-development || local.is-test ? 1 : 0
  security_group_id            = aws_security_group.sg_ssogen_internal_alb[count.index].id
  description                  = "Allow HTTPS (4443) to backend SSOGEN EC2s"
  from_port                    = 4443
  to_port                      = 4443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ssogen_sg[0].id
}

# Allow outbound HTTPS (7001) only to backend SSOGEN EC2s
resource "aws_vpc_security_group_egress_rule" "egress_ssogen_internal_admin_backend" {
  count                        = local.is-development || local.is-test ? 1 : 0
  security_group_id            = aws_security_group.sg_ssogen_internal_alb[count.index].id
  description                  = "Allow HTTPS (7001) to backend SSOGEN EC2s"
  from_port                    = 7001
  to_port                      = 7001
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ssogen_sg[0].id
}
