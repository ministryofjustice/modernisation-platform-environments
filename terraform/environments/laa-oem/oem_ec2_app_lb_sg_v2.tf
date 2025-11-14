resource "aws_security_group" "load_balancer_security_group" {
  count = 0
  name_prefix = "${local.application_name}-load-balancer-sg-"
  description = "Access to the EBS App server"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(tomap(
    { "Name" = "${local.application_name}-app-lb-sg" }
  ), local.tags)
}

## Egress Rules for load_balancer_security_group
#resource "aws_vpc_security_group_egress_rule" "lb_sg_egress_all_0_0_cidr" {
#  security_group_id = aws_security_group.load_balancer_security_group.id
#  description       = "Allow all outbound traffic"
#  ip_protocol       = "-1"
#  cidr_ipv4         = "0.0.0.0/0"
#
#  tags = {
#    Name = "Allow all outbound traffic"
#  }
#}
#
## Ingress Rules for load_balancer_security_group - HTTPS (443)
#resource "aws_vpc_security_group_ingress_rule" "lb_sg_ingress_tcp_443_443_cidr_1" {
#  security_group_id = aws_security_group.load_balancer_security_group.id
#  description       = "HTTPS access from shared VPC"
#  ip_protocol       = "tcp"
#  from_port         = 443
#  to_port           = 443
#  cidr_ipv4         = data.aws_vpc.shared.cidr_block
#
#  tags = {
#    Name = "HTTPS from shared VPC"
#  }
#}
#
#resource "aws_vpc_security_group_ingress_rule" "lb_sg_ingress_tcp_443_443_cidr_2" {
#  security_group_id = aws_security_group.load_balancer_security_group.id
#  description       = "HTTPS access from non-prod workspaces"
#  ip_protocol       = "tcp"
#  from_port         = 443
#  to_port           = 443
#  cidr_ipv4         = local.cidr_lz_workspaces_nonp
#
#  tags = {
#    Name = "HTTPS from non-prod workspaces"
#  }
#}
#
#resource "aws_vpc_security_group_ingress_rule" "lb_sg_ingress_tcp_443_443_cidr_3" {
#  security_group_id = aws_security_group.load_balancer_security_group.id
#  description       = "HTTPS access from prod workspaces"
#  ip_protocol       = "tcp"
#  from_port         = 443
#  to_port           = 443
#  cidr_ipv4         = local.cidr_lz_workspaces_prod
#
#  tags = {
#    Name = "HTTPS from prod workspaces"
#  }
#}
#
## Ingress Rules for load_balancer_security_group - Oracle EM Console HTTP (3872)
#resource "aws_vpc_security_group_ingress_rule" "lb_sg_ingress_tcp_3872_3872_cidr_1" {
#  security_group_id = aws_security_group.load_balancer_security_group.id
#  description       = "Oracle EM Console HTTP from shared VPC"
#  ip_protocol       = "tcp"
#  from_port         = 3872
#  to_port           = 3872
#  cidr_ipv4         = data.aws_vpc.shared.cidr_block
#
#  tags = {
#    Name = "Oracle EM Console HTTP from shared VPC"
#  }
#}
#
#resource "aws_vpc_security_group_ingress_rule" "lb_sg_ingress_tcp_3872_3872_cidr_2" {
#  security_group_id = aws_security_group.load_balancer_security_group.id
#  description       = "Oracle EM Console HTTP from non-prod workspaces"
#  ip_protocol       = "tcp"
#  from_port         = 3872
#  to_port           = 3872
#  cidr_ipv4         = local.cidr_lz_workspaces_nonp
#
#  tags = {
#    Name = "Oracle EM Console HTTP from non-prod workspaces"
#  }
#}
#
#resource "aws_vpc_security_group_ingress_rule" "lb_sg_ingress_tcp_3872_3872_cidr_3" {
#  security_group_id = aws_security_group.load_balancer_security_group.id
#  description       = "Oracle EM Console HTTP from prod workspaces"
#  ip_protocol       = "tcp"
#  from_port         = 3872
#  to_port           = 3872
#  cidr_ipv4         = local.cidr_lz_workspaces_prod
#
#  tags = {
#    Name = "Oracle EM Console HTTP from prod workspaces"
#  }
#}
#
#resource "aws_vpc_security_group_ingress_rule" "lb_sg_ingress_tcp_3872_3872_cidr_any" {
#  security_group_id = aws_security_group.load_balancer_security_group.id
#  description       = "Oracle EM Console HTTP from internet (public access)"
#  ip_protocol       = "tcp"
#  from_port         = 3872
#  to_port           = 3872
#  cidr_ipv4         = "0.0.0.0/0"
#
#  tags = {
#    Name = "Oracle EM Console HTTP from anywhere"
#  }
#}
#
## Ingress Rules for load_balancer_security_group - Oracle EM Console HTTPS (4903)
#resource "aws_vpc_security_group_ingress_rule" "lb_sg_ingress_tcp_4903_4903_cidr_1" {
#  security_group_id = aws_security_group.load_balancer_security_group.id
#  description       = "Oracle EM Console HTTPS from shared VPC"
#  ip_protocol       = "tcp"
#  from_port         = 4903
#  to_port           = 4903
#  cidr_ipv4         = data.aws_vpc.shared.cidr_block
#
#  tags = {
#    Name = "Oracle EM Console HTTPS from shared VPC"
#  }
#}
#
#resource "aws_vpc_security_group_ingress_rule" "lb_sg_ingress_tcp_4903_4903_cidr_2" {
#  security_group_id = aws_security_group.load_balancer_security_group.id
#  description       = "Oracle EM Console HTTPS from non-prod workspaces"
#  ip_protocol       = "tcp"
#  from_port         = 4903
#  to_port           = 4903
#  cidr_ipv4         = local.cidr_lz_workspaces_nonp
#
#  tags = {
#    Name = "Oracle EM Console HTTPS from non-prod workspaces"
#  }
#}
#
#resource "aws_vpc_security_group_ingress_rule" "lb_sg_ingress_tcp_4903_4903_cidr_3" {
#  security_group_id = aws_security_group.load_balancer_security_group.id
#  description       = "Oracle EM Console HTTPS from prod workspaces"
#  ip_protocol       = "tcp"
#  from_port         = 4903
#  to_port           = 4903
#  cidr_ipv4         = local.cidr_lz_workspaces_prod
#
#  tags = {
#    Name = "Oracle EM Console HTTPS from prod workspaces"
#  }
#}
#
#resource "aws_vpc_security_group_ingress_rule" "lb_sg_ingress_tcp_4903_4903_cidr_any" {
#  security_group_id = aws_security_group.load_balancer_security_group.id
#  description       = "Oracle EM Console HTTPS from internet (public access)"
#  ip_protocol       = "tcp"
#  from_port         = 4903
#  to_port           = 4903
#  cidr_ipv4         = "0.0.0.0/0"
#
#  tags = {
#    Name = "Oracle EM Console HTTPS from anywhere"
#  }
#}
#
## Ingress Rules for load_balancer_security_group - Oracle EM OMS (7102)
#resource "aws_vpc_security_group_ingress_rule" "lb_sg_ingress_tcp_7102_7102_cidr_1" {
#  security_group_id = aws_security_group.load_balancer_security_group.id
#  description       = "Oracle EM OMS port from shared VPC"
#  ip_protocol       = "tcp"
#  from_port         = 7102
#  to_port           = 7102
#  cidr_ipv4         = data.aws_vpc.shared.cidr_block
#
#  tags = {
#    Name = "Oracle EM OMS from shared VPC"
#  }
#}
#
#resource "aws_vpc_security_group_ingress_rule" "lb_sg_ingress_tcp_7102_7102_cidr_2" {
#  security_group_id = aws_security_group.load_balancer_security_group.id
#  description       = "Oracle EM OMS port from non-prod workspaces"
#  ip_protocol       = "tcp"
#  from_port         = 7102
#  to_port           = 7102
#  cidr_ipv4         = local.cidr_lz_workspaces_nonp
#
#  tags = {
#    Name = "Oracle EM OMS from non-prod workspaces"
#  }
#}
#
#resource "aws_vpc_security_group_ingress_rule" "lb_sg_ingress_tcp_7102_7102_cidr_3" {
#  security_group_id = aws_security_group.load_balancer_security_group.id
#  description       = "Oracle EM OMS port from prod workspaces"
#  ip_protocol       = "tcp"
#  from_port         = 7102
#  to_port           = 7102
#  cidr_ipv4         = local.cidr_lz_workspaces_prod
#
#  tags = {
#    Name = "Oracle EM OMS from prod workspaces"
#  }
#}
#
## Ingress Rules for load_balancer_security_group - Oracle EM additional port (7803)
#resource "aws_vpc_security_group_ingress_rule" "lb_sg_ingress_tcp_7803_7803_cidr_1" {
#  security_group_id = aws_security_group.load_balancer_security_group.id
#  description       = "Oracle EM additional port from shared VPC"
#  ip_protocol       = "tcp"
#  from_port         = 7803
#  to_port           = 7803
#  cidr_ipv4         = data.aws_vpc.shared.cidr_block
#
#  tags = {
#    Name = "Oracle EM port 7803 from shared VPC"
#  }
#}
#
#resource "aws_vpc_security_group_ingress_rule" "lb_sg_ingress_tcp_7803_7803_cidr_2" {
#  security_group_id = aws_security_group.load_balancer_security_group.id
#  description       = "Oracle EM additional port from non-prod workspaces"
#  ip_protocol       = "tcp"
#  from_port         = 7803
#  to_port           = 7803
#  cidr_ipv4         = local.cidr_lz_workspaces_nonp
#
#  tags = {
#    Name = "Oracle EM port 7803 from non-prod workspaces"
#  }
#}
#
#resource "aws_vpc_security_group_ingress_rule" "lb_sg_ingress_tcp_7803_7803_cidr_3" {
#  security_group_id = aws_security_group.load_balancer_security_group.id
#  description       = "Oracle EM additional port from prod workspaces"
#  ip_protocol       = "tcp"
#  from_port         = 7803
#  to_port           = 7803
#  cidr_ipv4         = local.cidr_lz_workspaces_prod
#
#  tags = {
#    Name = "Oracle EM port 7803 from prod workspaces"
#  }
#}
#
#resource "aws_vpc_security_group_ingress_rule" "lb_sg_ingress_tcp_7803_7803_cidr_any" {
#  security_group_id = aws_security_group.load_balancer_security_group.id
#  description       = "Oracle EM additional port from internet (public access)"
#  ip_protocol       = "tcp"
#  from_port         = 7803
#  to_port           = 7803
#  cidr_ipv4         = "0.0.0.0/0"
#
#  tags = {
#    Name = "Oracle EM port 7803 from anywhere"
#  }
#}
