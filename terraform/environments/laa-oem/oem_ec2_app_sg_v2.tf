resource "aws_security_group" "oem_app_security_group_1" {
  name_prefix = "${local.application_name}-app-server-sg-1-"
  description = "Access to the ebs app server"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(tomap(
    { "Name" = "${local.application_name}-app-server-sg-1" }
  ), local.tags)
}

# Egress Rules for oem_app_security_group_1
resource "aws_vpc_security_group_egress_rule" "oem_app_sg1_egress_all_0_0_cidr" {
  security_group_id = aws_security_group.oem_app_security_group_1.id
  ip_protocol       = "-1"
  from_port         = 0
  to_port           = 0
  cidr_ipv4         = "0.0.0.0/0"
}

# Ingress Rules for oem_app_security_group_1
resource "aws_vpc_security_group_ingress_rule" "oem_app_sg1_ingress_tcp_22_22_cidr_1" {
  security_group_id = aws_security_group.oem_app_security_group_1.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg1_ingress_tcp_22_22_cidr_2" {
  security_group_id = aws_security_group.oem_app_security_group_1.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.cidr_lz_workspaces_nonp
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg1_ingress_tcp_22_22_cidr_3" {
  security_group_id = aws_security_group.oem_app_security_group_1.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.cidr_lz_workspaces_prod
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg1_ingress_icmp_neg1_neg1_cidr_1" {
  security_group_id = aws_security_group.oem_app_security_group_1.id
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg1_ingress_icmp_neg1_neg1_cidr_2" {
  security_group_id = aws_security_group.oem_app_security_group_1.id
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = local.cidr_lz_workspaces_nonp
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg1_ingress_icmp_neg1_neg1_cidr_3" {
  security_group_id = aws_security_group.oem_app_security_group_1.id
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = local.cidr_lz_workspaces_prod
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg1_ingress_tcp_1159_1159_cidr" {
  security_group_id = aws_security_group.oem_app_security_group_1.id
  ip_protocol       = "tcp"
  from_port         = 1159
  to_port           = 1159
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg1_ingress_tcp_1159_1159_sg_lb" {
  security_group_id            = aws_security_group.oem_app_security_group_1.id
  ip_protocol                  = "tcp"
  from_port                    = 1159
  to_port                      = 1159
  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg1_ingress_tcp_1521_1521_cidr" {
  security_group_id = aws_security_group.oem_app_security_group_1.id
  ip_protocol       = "tcp"
  from_port         = 1521
  to_port           = 1521
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg1_ingress_tcp_1521_1521_sg_lb" {
  security_group_id            = aws_security_group.oem_app_security_group_1.id
  ip_protocol                  = "tcp"
  from_port                    = 1521
  to_port                      = 1521
  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg1_ingress_tcp_1830_1849_cidr" {
  security_group_id = aws_security_group.oem_app_security_group_1.id
  ip_protocol       = "tcp"
  from_port         = 1830
  to_port           = 1849
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg1_ingress_tcp_1830_1849_sg_lb" {
  security_group_id            = aws_security_group.oem_app_security_group_1.id
  ip_protocol                  = "tcp"
  from_port                    = 1830
  to_port                      = 1849
  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg1_ingress_tcp_2049_2049_cidr" {
  security_group_id = aws_security_group.oem_app_security_group_1.id
  ip_protocol       = "tcp"
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg1_ingress_tcp_2049_2049_sg_lb" {
  security_group_id            = aws_security_group.oem_app_security_group_1.id
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg1_ingress_tcp_3872_3872_cidr" {
  security_group_id = aws_security_group.oem_app_security_group_1.id
  ip_protocol       = "tcp"
  from_port         = 3872
  to_port           = 3872
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg1_ingress_tcp_3872_3872_sg_lb" {
  security_group_id            = aws_security_group.oem_app_security_group_1.id
  ip_protocol                  = "tcp"
  from_port                    = 3872
  to_port                      = 3872
  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg1_ingress_tcp_4889_4889_cidr" {
  security_group_id = aws_security_group.oem_app_security_group_1.id
  ip_protocol       = "tcp"
  from_port         = 4889
  to_port           = 4889
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg1_ingress_tcp_4889_4889_sg_lb" {
  security_group_id            = aws_security_group.oem_app_security_group_1.id
  ip_protocol                  = "tcp"
  from_port                    = 4889
  to_port                      = 4889
  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg1_ingress_tcp_4903_4903_cidr" {
  security_group_id = aws_security_group.oem_app_security_group_1.id
  ip_protocol       = "tcp"
  from_port         = 4903
  to_port           = 4903
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg1_ingress_tcp_4903_4903_sg_lb" {
  security_group_id            = aws_security_group.oem_app_security_group_1.id
  ip_protocol                  = "tcp"
  from_port                    = 4903
  to_port                      = 4903
  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg1_ingress_tcp_7101_7102_cidr" {
  security_group_id = aws_security_group.oem_app_security_group_1.id
  ip_protocol       = "tcp"
  from_port         = 7101
  to_port           = 7102
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg1_ingress_tcp_7101_7102_sg_lb" {
  security_group_id            = aws_security_group.oem_app_security_group_1.id
  ip_protocol                  = "tcp"
  from_port                    = 7101
  to_port                      = 7102
  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
}

resource "aws_security_group" "oem_app_security_group_2" {
  name_prefix = "${local.application_name}-app-server-sg-2-"
  description = "Access to the ebs app server"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(tomap(
    { "Name" = "${local.application_name}-app-server-sg-2" }
  ), local.tags)
}

# Ingress Rules for oem_app_security_group_2
resource "aws_vpc_security_group_ingress_rule" "oem_app_sg2_ingress_tcp_7202_7202_cidr" {
  security_group_id = aws_security_group.oem_app_security_group_2.id
  ip_protocol       = "tcp"
  from_port         = 7202
  to_port           = 7202
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg2_ingress_tcp_7202_7202_sg_lb" {
  security_group_id            = aws_security_group.oem_app_security_group_2.id
  ip_protocol                  = "tcp"
  from_port                    = 7202
  to_port                      = 7202
  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg2_ingress_tcp_7301_7301_cidr" {
  security_group_id = aws_security_group.oem_app_security_group_2.id
  ip_protocol       = "tcp"
  from_port         = 7301
  to_port           = 7301
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg2_ingress_tcp_7301_7301_sg_lb" {
  security_group_id            = aws_security_group.oem_app_security_group_2.id
  ip_protocol                  = "tcp"
  from_port                    = 7301
  to_port                      = 7301
  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg2_ingress_tcp_7403_7403_cidr" {
  security_group_id = aws_security_group.oem_app_security_group_2.id
  ip_protocol       = "tcp"
  from_port         = 7403
  to_port           = 7403
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg2_ingress_tcp_7403_7403_sg_lb" {
  security_group_id            = aws_security_group.oem_app_security_group_2.id
  ip_protocol                  = "tcp"
  from_port                    = 7403
  to_port                      = 7403
  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg2_ingress_tcp_7788_7788_cidr" {
  security_group_id = aws_security_group.oem_app_security_group_2.id
  ip_protocol       = "tcp"
  from_port         = 7788
  to_port           = 7788
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg2_ingress_tcp_7788_7788_sg_lb" {
  security_group_id            = aws_security_group.oem_app_security_group_2.id
  ip_protocol                  = "tcp"
  from_port                    = 7788
  to_port                      = 7788
  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg2_ingress_tcp_7799_7799_cidr" {
  security_group_id = aws_security_group.oem_app_security_group_2.id
  ip_protocol       = "tcp"
  from_port         = 7799
  to_port           = 7799
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg2_ingress_tcp_7799_7799_sg_lb" {
  security_group_id            = aws_security_group.oem_app_security_group_2.id
  ip_protocol                  = "tcp"
  from_port                    = 7799
  to_port                      = 7799
  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg2_ingress_tcp_7803_7803_cidr" {
  security_group_id = aws_security_group.oem_app_security_group_2.id
  ip_protocol       = "tcp"
  from_port         = 7803
  to_port           = 7803
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg2_ingress_tcp_7803_7803_sg_lb" {
  security_group_id            = aws_security_group.oem_app_security_group_2.id
  ip_protocol                  = "tcp"
  from_port                    = 7803
  to_port                      = 7803
  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg2_ingress_tcp_9788_9788_cidr" {
  security_group_id = aws_security_group.oem_app_security_group_2.id
  ip_protocol       = "tcp"
  from_port         = 9788
  to_port           = 9788
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg2_ingress_tcp_9788_9788_sg_lb" {
  security_group_id            = aws_security_group.oem_app_security_group_2.id
  ip_protocol                  = "tcp"
  from_port                    = 9788
  to_port                      = 9788
  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg2_ingress_tcp_9851_9851_cidr" {
  security_group_id = aws_security_group.oem_app_security_group_2.id
  ip_protocol       = "tcp"
  from_port         = 9851
  to_port           = 9851
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "oem_app_sg2_ingress_tcp_9851_9851_sg_lb" {
  security_group_id            = aws_security_group.oem_app_security_group_2.id
  ip_protocol                  = "tcp"
  from_port                    = 9851
  to_port                      = 9851
  referenced_security_group_id = aws_security_group.load_balancer_security_group.id
}
