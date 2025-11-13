# Oracle HTTP Server SSL Listen Port 4443
# Oracle WebLogic Server Node Manager Port 5556
# Oracle WebLogic Server Listen Port for Administration Server 7001
# Oracle WebLogic Server SSL Listen Port for Administration Server 7002
# Oracle WebLogic Server Listen Port for Managed Server 8001

resource "aws_security_group" "oem_wl_security_group_1" {
  count       = length(local.application_data.accounts[local.environment].ec2_oem_ami_id_wl) > 0 ? 1 : 0
  name_prefix = "${local.application_name}-wl-server-sg-1-"
  description = "Access to the Weblogic server"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(tomap(
    { "Name" = "${local.application_name}-wl-server-sg-1" }
  ), local.tags)
}

# Egress Rules for oem_wl_security_group_1
resource "aws_vpc_security_group_egress_rule" "oem_wl_sg1_egress_all_0_0_cidr" {
  count             = length(local.application_data.accounts[local.environment].ec2_oem_ami_id_wl) > 0 ? 1 : 0
  security_group_id = aws_security_group.oem_wl_security_group_1[0].id
  ip_protocol       = "-1"
  from_port         = 0
  to_port           = 0
  cidr_ipv4         = "0.0.0.0/0"
}

# Ingress Rules for oem_wl_security_group_1
resource "aws_vpc_security_group_ingress_rule" "oem_wl_sg1_ingress_tcp_22_22_cidr_1" {
  count             = length(local.application_data.accounts[local.environment].ec2_oem_ami_id_wl) > 0 ? 1 : 0
  security_group_id = aws_security_group.oem_wl_security_group_1[0].id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_wl_sg1_ingress_tcp_22_22_cidr_2" {
  count             = length(local.application_data.accounts[local.environment].ec2_oem_ami_id_wl) > 0 ? 1 : 0
  security_group_id = aws_security_group.oem_wl_security_group_1[0].id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.cidr_lz_workspaces_nonp
}

resource "aws_vpc_security_group_ingress_rule" "oem_wl_sg1_ingress_tcp_22_22_cidr_3" {
  count             = length(local.application_data.accounts[local.environment].ec2_oem_ami_id_wl) > 0 ? 1 : 0
  security_group_id = aws_security_group.oem_wl_security_group_1[0].id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.cidr_lz_workspaces_prod
}

resource "aws_vpc_security_group_ingress_rule" "oem_wl_sg1_ingress_icmp_neg1_neg1_cidr_1" {
  count             = length(local.application_data.accounts[local.environment].ec2_oem_ami_id_wl) > 0 ? 1 : 0
  security_group_id = aws_security_group.oem_wl_security_group_1[0].id
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_wl_sg1_ingress_icmp_neg1_neg1_cidr_2" {
  count             = length(local.application_data.accounts[local.environment].ec2_oem_ami_id_wl) > 0 ? 1 : 0
  security_group_id = aws_security_group.oem_wl_security_group_1[0].id
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = local.cidr_lz_workspaces_nonp
}

resource "aws_vpc_security_group_ingress_rule" "oem_wl_sg1_ingress_icmp_neg1_neg1_cidr_3" {
  count             = length(local.application_data.accounts[local.environment].ec2_oem_ami_id_wl) > 0 ? 1 : 0
  security_group_id = aws_security_group.oem_wl_security_group_1[0].id
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = local.cidr_lz_workspaces_prod
}

resource "aws_vpc_security_group_ingress_rule" "oem_wl_sg1_ingress_tcp_4443_4443_cidr" {
  count             = length(local.application_data.accounts[local.environment].ec2_oem_ami_id_wl) > 0 ? 1 : 0
  security_group_id = aws_security_group.oem_wl_security_group_1[0].id
  ip_protocol       = "tcp"
  from_port         = 4443
  to_port           = 4443
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_wl_sg1_ingress_tcp_4443_4443_sg_lb" {
  count                        = length(local.application_data.accounts[local.environment].ec2_oem_ami_id_wl) > 0 ? 1 : 0
  security_group_id            = aws_security_group.oem_wl_security_group_1[0].id
  ip_protocol                  = "tcp"
  from_port                    = 4443
  to_port                      = 4443
  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "oem_wl_sg1_ingress_tcp_5556_5556_cidr" {
  count             = length(local.application_data.accounts[local.environment].ec2_oem_ami_id_wl) > 0 ? 1 : 0
  security_group_id = aws_security_group.oem_wl_security_group_1[0].id
  ip_protocol       = "tcp"
  from_port         = 5556
  to_port           = 5556
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_wl_sg1_ingress_tcp_5556_5556_sg_lb" {
  count                        = length(local.application_data.accounts[local.environment].ec2_oem_ami_id_wl) > 0 ? 1 : 0
  security_group_id            = aws_security_group.oem_wl_security_group_1[0].id
  ip_protocol                  = "tcp"
  from_port                    = 5556
  to_port                      = 5556
  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "oem_wl_sg1_ingress_tcp_7001_7001_cidr" {
  count             = length(local.application_data.accounts[local.environment].ec2_oem_ami_id_wl) > 0 ? 1 : 0
  security_group_id = aws_security_group.oem_wl_security_group_1[0].id
  ip_protocol       = "tcp"
  from_port         = 7001
  to_port           = 7001
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_wl_sg1_ingress_tcp_7001_7001_sg_lb" {
  count                        = length(local.application_data.accounts[local.environment].ec2_oem_ami_id_wl) > 0 ? 1 : 0
  security_group_id            = aws_security_group.oem_wl_security_group_1[0].id
  ip_protocol                  = "tcp"
  from_port                    = 7001
  to_port                      = 7001
  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "oem_wl_sg1_ingress_tcp_7002_7002_cidr" {
  count             = length(local.application_data.accounts[local.environment].ec2_oem_ami_id_wl) > 0 ? 1 : 0
  security_group_id = aws_security_group.oem_wl_security_group_1[0].id
  ip_protocol       = "tcp"
  from_port         = 7002
  to_port           = 7002
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_wl_sg1_ingress_tcp_7002_7002_sg_lb" {
  count                        = length(local.application_data.accounts[local.environment].ec2_oem_ami_id_wl) > 0 ? 1 : 0
  security_group_id            = aws_security_group.oem_wl_security_group_1[0].id
  ip_protocol                  = "tcp"
  from_port                    = 7002
  to_port                      = 7002
  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "oem_wl_sg1_ingress_tcp_8001_8001_cidr" {
  count             = length(local.application_data.accounts[local.environment].ec2_oem_ami_id_wl) > 0 ? 1 : 0
  security_group_id = aws_security_group.oem_wl_security_group_1[0].id
  ip_protocol       = "tcp"
  from_port         = 8001
  to_port           = 8001
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_wl_sg1_ingress_tcp_8001_8001_sg_lb" {
  count                        = length(local.application_data.accounts[local.environment].ec2_oem_ami_id_wl) > 0 ? 1 : 0
  security_group_id            = aws_security_group.oem_wl_security_group_1[0].id
  ip_protocol                  = "tcp"
  from_port                    = 8001
  to_port                      = 8001
  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
}
