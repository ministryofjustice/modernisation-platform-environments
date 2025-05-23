#--ALB Admin
resource "aws_security_group" "alb_admin" {
  name        = "${local.application_data.accounts[local.environment].app_name}_alb_admin"
  description = "Controls Traffic for SOA Admin Application"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_security_group_rule" "alb_admin_ingress_80" {
  security_group_id = aws_security_group.alb_admin.id
  type              = "ingress"
  description       = "Admin HTTP" #--Why?
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
}

resource "aws_security_group_rule" "alb_admin_ingress_443" {
  security_group_id = aws_security_group.alb_admin.id
  type              = "ingress"
  description       = "Admin HTTPS"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
}

resource "aws_security_group_rule" "alb_admin_ingress_7001" {
  security_group_id = aws_security_group.alb_admin.id
  type              = "ingress"
  description       = "Admin Weblogic" #--Maybe?
  protocol          = "TCP"
  from_port         = 7001
  to_port           = 7001
  cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
}

resource "aws_security_group_rule" "alb_admin_egress_all" {
  security_group_id = aws_security_group.alb_admin.id
  type              = "egress"
  description       = "All"
  protocol          = "TCP"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"] #--Tighten - AW
}

#--Managed
resource "aws_security_group" "alb_managed" {
  name        = "${local.application_data.accounts[local.environment].app_name}_alb_managed"
  description = "Controls Traffic for SOA Managed Application"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_security_group_rule" "alb_managed_ingress_80" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "ingress"
  description       = "Managed HTTP" #--Why?
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
}

resource "aws_security_group_rule" "alb_managed_ingress_443" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "ingress"
  description       = "Managed HTTPS"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
}

resource "aws_security_group_rule" "alb_managed_ingress_7001" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "ingress"
  description       = "Managed Weblogic" #--Maybe?
  protocol          = "TCP"
  from_port         = 7001
  to_port           = 7001
  cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
}

resource "aws_security_group_rule" "alb_managed_egress_all" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "egress"
  description       = "All"
  protocol          = "TCP"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"] #--Tighten - AW
}

#--ECS Tasks Admin
resource "aws_security_group" "ecs_tasks_admin" {
  name_prefix = "${local.application_data.accounts[local.environment].app_name}_ecs_tasks_admin"
  description = "SOA Admin - Controls Traffic Between VPC and ECS Control Plane"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_security_group_rule" "ecs_tasks_admin_server" {
  security_group_id = aws_security_group.ecs_tasks_admin.id
  type              = "ingress"
  description       = "SOA Admin Server" #--Why?
  protocol          = "TCP"
  from_port         = local.application_data.accounts[local.environment].admin_server_port
  to_port           = local.application_data.accounts[local.environment].admin_server_port
  cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
}

#--ECS Tasks Managed
resource "aws_security_group" "ecs_tasks_managed" {
  name_prefix = "${local.application_data.accounts[local.environment].app_name}_ecs_tasks_managed"
  description = "SOA Managed - Controls Traffic Between VPC and ECS Control Plane"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_security_group_rule" "ecs_tasks_managed_server" {
  security_group_id = aws_security_group.ecs_tasks_managed.id
  type              = "ingress"
  description       = "SOA Managed Server"
  protocol          = "TCP"
  from_port         = local.application_data.accounts[local.environment].managed_server_port
  to_port           = local.application_data.accounts[local.environment].managed_server_port
  cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
}

resource "aws_security_group_rule" "ecs_tasks_managed_7" {
  security_group_id = aws_security_group.ecs_tasks_managed.id
  type              = "ingress"
  description       = "SOA Managed Application" #--Why?
  protocol          = "TCP"
  from_port         = 7
  to_port           = 7
  cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
}

resource "aws_security_group_rule" "ecs_tasks_managed_7574_tcp" {
  security_group_id = aws_security_group.ecs_tasks_managed.id
  type              = "ingress"
  description       = "SOA Managed Application" #--Why?
  protocol          = "TCP"
  from_port         = 7574
  to_port           = 7574
  cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
}

resource "aws_security_group_rule" "ecs_tasks_managed_8088_8089" {
  security_group_id = aws_security_group.ecs_tasks_managed.id
  type              = "ingress"
  description       = "SOA Managed Application" #--Why?
  protocol          = "TCP"
  from_port         = 8088
  to_port           = 8089
  cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
}

resource "aws_security_group_rule" "ecs_tasks_managed_egress_all" {
  security_group_id = aws_security_group.ecs_tasks_managed.id
  type              = "egress"
  description       = "All"
  protocol          = "TCP"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"] #--Tighten - AW.
}

#--Cluster EC2 Instances
resource "aws_security_group" "cluster_ec2" {
  name        = "${local.application_data.accounts[local.environment].app_name}-cluster-ec2-security-group"
  description = "controls access to the cluster ec2 instance"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_security_group_rule" "cluster_ec2_ingress_1521" {
  security_group_id = aws_security_group.cluster_ec2.id
  type              = "ingress"
  description       = "Application Traffic"
  protocol          = "TCP" #--What?
  from_port         = 1521
  to_port           = 1521
  cidr_blocks       = ["0.0.0.0/0"] #--Tighten - AW.
}

resource "aws_security_group_rule" "cluster_ec2_ingress_3872" {
  security_group_id = aws_security_group.cluster_ec2.id
  type              = "ingress"
  description       = "Application Traffic"
  protocol          = "TCP" #--What?
  from_port         = 3872
  to_port           = 3872
  cidr_blocks       = ["0.0.0.0/0"] #--Tighten - AW.
}

resource "aws_security_group_rule" "cluster_ec2_ingress_4903" {
  security_group_id = aws_security_group.cluster_ec2.id
  type              = "ingress"
  description       = "Application Traffic"
  protocol          = "TCP" #--What?
  from_port         = 4903
  to_port           = 4903
  cidr_blocks       = ["0.0.0.0/0"] #--Tighten - AW.
}

resource "aws_security_group_rule" "cluster_ec2_egress_all" {
  security_group_id = aws_security_group.cluster_ec2.id
  type              = "egress"
  description       = "All Egress"
  protocol          = "TCP"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"] #--Tighten - AW.
}
