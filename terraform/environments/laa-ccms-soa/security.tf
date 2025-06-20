#--ALB Admin
resource "aws_security_group" "alb_admin" {
  name        = "${local.application_data.accounts[local.environment].app_name}_alb_admin"
  description = "Controls Traffic for SOA Admin Application"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_security_group_rule" "alb_admin_ingress_80" {
  security_group_id = aws_security_group.alb_admin.id
  type              = "ingress"
  description       = "Admin HTTP - Private Subnets" #--Why?
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
}

resource "aws_security_group_rule" "alb_admin_ingress_443" {
  security_group_id = aws_security_group.alb_admin.id
  type              = "ingress"
  description       = "Admin HTTPS - Private Subnets"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
}

resource "aws_security_group_rule" "alb_admin_ingress_7001" {
  security_group_id = aws_security_group.alb_admin.id
  type              = "ingress"
  description       = "Admin Weblogic - Internal Subnets"
  protocol          = "TCP"
  from_port         = 7001
  to_port           = 7001
  cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
}

resource "aws_security_group_rule" "alb_admin_workspace_ingress_80" {
  security_group_id = aws_security_group.alb_admin.id
  type              = "ingress"
  description       = "Admin Weblogic - AWS Workspaces" #--Why?
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = [local.application_data.accounts[local.environment].aws_workspace_cidr]
}

resource "aws_security_group_rule" "alb_admin_workspace_ingress_443" {
  security_group_id = aws_security_group.alb_admin.id
  type              = "ingress"
  description       = "Admin Weblogic HTTPS - AWS Workspaces"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [local.application_data.accounts[local.environment].aws_workspace_cidr]
}

resource "aws_security_group_rule" "alb_admin_workspace_ingress_7001" {
  security_group_id = aws_security_group.alb_admin.id
  type              = "ingress"
  description       = "Admin Weblogic - AWS Workspaces"
  protocol          = "TCP"
  from_port         = 7001
  to_port           = 7001
  cidr_blocks       = [local.application_data.accounts[local.environment].aws_workspace_cidr]
}

resource "aws_security_group_rule" "alb_admin_egress_all" {
  security_group_id = aws_security_group.alb_admin.id
  type              = "egress"
  description       = "All"
  protocol          = -1
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
  description       = "EM HTTP - Internal Subnets" #--Why?
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
}

resource "aws_security_group_rule" "alb_managed_ingress_443" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "ingress"
  description       = "HTTPS - Internal Subnets"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
}

resource "aws_security_group_rule" "alb_managed_ingress_443_databases" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "ingress"
  description       = "HTTPS - Database Connections"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [data.aws_subnet.data_subnets_a.cidr_block, data.aws_subnet.data_subnets_b.cidr_block, data.aws_subnet.data_subnets_c.cidr_block]
}

resource "aws_security_group_rule" "alb_managed_ingress_8001" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "ingress"
  description       = "EM Weblogic - Internal Subnets"
  protocol          = "TCP"
  from_port         = 8001
  to_port           = 8001
  cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
}

resource "aws_security_group_rule" "alb_managed_ingress_cp80" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "ingress"
  description       = "EM HTTP - Cloud Platform" #--Why?
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = [local.application_data.accounts[local.environment].cloud_platform_cidr]
}

resource "aws_security_group_rule" "alb_managed_ingress_cp443" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "ingress"
  description       = "EM HTTPS - Cloud Platform" #--Why?
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [local.application_data.accounts[local.environment].cloud_platform_cidr]
}

resource "aws_security_group_rule" "alb_managed_ingress_cp8001" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "ingress"
  description       = "EM Weblogic - Cloud Platform"
  protocol          = "TCP"
  from_port         = 8001
  to_port           = 8001
  cidr_blocks       = [local.application_data.accounts[local.environment].cloud_platform_cidr]
}

resource "aws_security_group_rule" "alb_managed_egress_all" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "egress"
  description       = "All"
  protocol          = -1
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
  description       = "SOA Admin Server"
  protocol          = "TCP"
  from_port         = local.application_data.accounts[local.environment].admin_server_port
  to_port           = local.application_data.accounts[local.environment].admin_server_port
  cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
}

resource "aws_security_group_rule" "ecs_tasks_admin_egress_all" {
  security_group_id = aws_security_group.ecs_tasks_admin.id
  type              = "egress"
  description       = "All"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"] #--Tighten - AW.
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

resource "aws_security_group_rule" "ecs_tasks_managed_egress_all" {
  security_group_id = aws_security_group.ecs_tasks_managed.id
  type              = "egress"
  description       = "All"
  protocol          = -1
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

resource "aws_security_group_rule" "cluster_ec2_egress_all" {
  security_group_id = aws_security_group.cluster_ec2.id
  type              = "egress"
  description       = "All Egress"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"] #--Tighten - AW.
}

#--Database SOA
resource "aws_security_group" "soa_db" {
  name_prefix = "soa_allow_db"
  description = "Allow DB inbound traffic"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_ingress_rule" "soa_db_ingress" {
  count             = length(local.private_subnets_cidr_blocks)
  security_group_id = aws_security_group.soa_db.id
  description       = "Application to Database Ingress"
  ip_protocol       = "TCP"
  from_port         = 1521
  to_port           = 1521
  cidr_ipv4         = local.private_subnets_cidr_blocks[count.index]
}

resource "aws_vpc_security_group_ingress_rule" "soa_db_workspace_ingress" {
  security_group_id = aws_security_group.soa_db.id
  description       = "Workspace to Database Ingress"
  ip_protocol       = "TCP"
  from_port         = 1521
  to_port           = 1521
  cidr_ipv4         = local.application_data.accounts[local.environment].aws_workspace_cidr
}

resource "aws_security_group_rule" "soa_db_egress_all" {
  security_group_id = aws_security_group.soa_db.id
  type              = "egress"
  description       = "All Egress"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"] #--Tighten - AW.
}

#--Database TDS
resource "aws_security_group" "tds_db" {
  name        = "ccms-soa-tds-allow-db"
  description = "Allow DB inbound traffic"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_ingress_rule" "tds_db_ingress" {
  count             = length(local.private_subnets_cidr_blocks)
  security_group_id = aws_security_group.tds_db.id
  description       = "Database Ingress"
  ip_protocol       = "TCP"
  from_port         = 1521
  to_port           = 1521
  cidr_ipv4         = local.private_subnets_cidr_blocks[count.index]
}

resource "aws_vpc_security_group_ingress_rule" "tds_db_workspace_ingress" {
  security_group_id = aws_security_group.tds_db.id
  description       = "Workspace to Database Ingress"
  ip_protocol       = "TCP"
  from_port         = 1521
  to_port           = 1521
  cidr_ipv4         = local.application_data.accounts[local.environment].aws_workspace_cidr
}

resource "aws_vpc_security_group_ingress_rule" "tds_db_workspace_ingress_prod" {
  count             = local.is-production ? 1 : 0
  security_group_id = aws_security_group.tds_db.id
  description       = "Workspace to Database Ingress"
  ip_protocol       = "TCP"
  from_port         = 1521
  to_port           = 1521
  cidr_ipv4         = local.application_data.accounts[local.environment].workspace_cidr_prod
}

resource "aws_security_group_rule" "tds_db_egress_all" {
  security_group_id = aws_security_group.tds_db.id
  type              = "egress"
  description       = "All Egress"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"] #--Tighten - AW.
}

#--EFS
resource "aws_security_group" "efs-security-group" {
  name_prefix = "${local.application_name}-efs-security-group"
  description = "allow inbound access from container instances"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_ingress_rule" "efs-security-group-ingress" {
  count             = length(local.private_subnets_cidr_blocks)
  description       = "Allow inbound access from container instances"
  security_group_id = aws_security_group.efs-security-group.id
  ip_protocol       = "tcp"
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = local.private_subnets_cidr_blocks[count.index]
}

resource "aws_vpc_security_group_egress_rule" "efs-security-group-egress" {
  description       = "Allow connections to EFS"
  security_group_id = aws_security_group.efs-security-group.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
