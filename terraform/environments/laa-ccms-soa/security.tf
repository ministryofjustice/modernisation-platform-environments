############################################################
# ALB – ADMIN
############################################################
resource "aws_security_group" "alb_admin" {
  name        = "${local.application_data.accounts[local.environment].app_name}_alb_admin"
  description = "Controls Traffic for SOA Admin Application"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_security_group_rule" "alb_admin_ingress_80" {
  security_group_id = aws_security_group.alb_admin.id
  type              = "ingress"
  description       = "Admin HTTP - Private Subnets"
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = [
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
  ]
}

resource "aws_security_group_rule" "alb_admin_ingress_443" {
  security_group_id = aws_security_group.alb_admin.id
  type              = "ingress"
  description       = "Admin HTTPS - Private Subnets"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
  ]
}

resource "aws_security_group_rule" "alb_admin_ingress_7001" {
  security_group_id = aws_security_group.alb_admin.id
  type              = "ingress"
  description       = "Admin Weblogic - Internal Subnets"
  protocol          = "TCP"
  from_port         = 7001
  to_port           = 7001
  cidr_blocks       = [
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
  ]
}

resource "aws_security_group_rule" "alb_admin_workspace_ingress_80" {
  security_group_id = aws_security_group.alb_admin.id
  type              = "ingress"
  description       = "Admin Weblogic HTTP - AWS Workspaces"
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
  description       = "Allow all outbound"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

############################################################
# ALB – MANAGED
############################################################
resource "aws_security_group" "alb_managed" {
  name        = "${local.application_data.accounts[local.environment].app_name}_alb_managed"
  description = "Controls Traffic for SOA Managed Application"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_security_group_rule" "alb_managed_ingress_80" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "ingress"
  description       = "Managed HTTP - Internal Subnets"
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = [
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
  ]
}

resource "aws_security_group_rule" "alb_managed_ingress_443" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "ingress"
  description       = "Managed HTTPS - Internal Subnets"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
  ]
}

resource "aws_security_group_rule" "alb_managed_ingress_443_databases" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "ingress"
  description       = "Managed HTTPS - Database Subnets"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [
    data.aws_subnet.data_subnets_a.cidr_block,
    data.aws_subnet.data_subnets_b.cidr_block,
    data.aws_subnet.data_subnets_c.cidr_block
  ]
}

resource "aws_security_group_rule" "alb_managed_workspace_ingress_443" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "ingress"
  description       = "Managed HTTPS - AWS Workspaces"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [local.application_data.accounts[local.environment].aws_workspace_cidr]
}

resource "aws_security_group_rule" "alb_managed_ingress_8001" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "ingress"
  description       = "Managed Weblogic - Internal Subnets"
  protocol          = "TCP"
  from_port         = 8001
  to_port           = 8001
  cidr_blocks       = [
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
  ]
}

resource "aws_security_group_rule" "alb_managed_ingress_cp80" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "ingress"
  description       = "Managed HTTP - Cloud Platform"
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = [local.application_data.accounts[local.environment].cloud_platform_cidr]
}

resource "aws_security_group_rule" "alb_managed_ingress_cp443" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "ingress"
  description       = "Managed HTTPS - Cloud Platform"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [local.application_data.accounts[local.environment].cloud_platform_cidr]
}

resource "aws_security_group_rule" "alb_managed_ingress_cp8001" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "ingress"
  description       = "Managed Weblogic - Cloud Platform"
  protocol          = "TCP"
  from_port         = 8001
  to_port           = 8001
  cidr_blocks       = [local.application_data.accounts[local.environment].cloud_platform_cidr]
}

resource "aws_security_group_rule" "alb_managed_ingress_nec80" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "ingress"
  description       = "Managed HTTP - NEC"
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = [local.application_data.accounts[local.environment].northgate_proxy]
}

resource "aws_security_group_rule" "alb_managed_ingress_nec443" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "ingress"
  description       = "Managed HTTPS - NEC"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [local.application_data.accounts[local.environment].northgate_proxy]
}

resource "aws_security_group_rule" "alb_managed_egress_all" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "egress"
  description       = "Allow all outbound"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

############################################################
# ECS ADMIN TASKS
############################################################
resource "aws_security_group" "ecs_tasks_admin" {
  name_prefix = "${local.application_data.accounts[local.environment].app_name}_ecs_tasks_admin"
  description = "SOA Admin - ECS Control Plane"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_security_group_rule" "ecs_tasks_admin_server" {
  security_group_id = aws_security_group.ecs_tasks_admin.id
  type              = "ingress"
  description       = "Admin Server Port"
  protocol          = "TCP"
  from_port         = local.application_data.accounts[local.environment].admin_server_port
  to_port           = local.application_data.accounts[local.environment].admin_server_port
  cidr_blocks       = [
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
  ]
}

resource "aws_security_group_rule" "ecs_tasks_admin_egress_all" {
  security_group_id = aws_security_group.ecs_tasks_admin.id
  type              = "egress"
  description       = "Allow all outbound"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

############################################################
# ECS MANAGED TASKS
############################################################
resource "aws_security_group" "ecs_tasks_managed" {
  name_prefix = "${local.application_data.accounts[local.environment].app_name}_ecs_tasks_managed"
  description = "SOA Managed - ECS Control Plane"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_security_group_rule" "ecs_tasks_managed_server" {
  security_group_id = aws_security_group.ecs_tasks_managed.id
  type              = "ingress"
  description       = "Managed Server Port"
  protocol          = "TCP"
  from_port         = local.application_data.accounts[local.environment].managed_server_port
  to_port           = local.application_data.accounts[local.environment].managed_server_port
  cidr_blocks       = [
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
  ]
}

resource "aws_security_group_rule" "ecs_tasks_managed_egress_all" {
  security_group_id = aws_security_group.ecs_tasks_managed.id
  type              = "egress"
  description       = "Allow all outbound"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

############################################################
# CLUSTER EC2 INSTANCES
############################################################
resource "aws_security_group" "cluster_ec2" {
  name        = "${local.application_data.accounts[local.environment].app_name}-cluster-ec2-security-group"
  description = "Cluster EC2 instance SG"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_security_group_rule" "cluster_ec2_egress_all" {
  security_group_id = aws_security_group.cluster_ec2.id
  type              = "egress"
  description       = "Allow all outbound"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

############################################################
# SOA DATABASE
############################################################
resource "aws_security_group" "soa_db" {
  name_prefix = "soa_allow_db"
  description = "Allow DB inbound traffic"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_ingress_rule" "soa_db_ingress" {
  count             = length(local.private_subnets_cidr_blocks)
  security_group_id = aws_security_group.soa_db.id
  description       = "Application to SOA Database"
  ip_protocol       = "TCP"
  from_port         = 1521
  to_port           = 1521
  cidr_ipv4         = local.private_subnets_cidr_blocks[count.index]
}

resource "aws_vpc_security_group_ingress_rule" "soa_db_workspace_ingress" {
  security_group_id = aws_security_group.soa_db.id
  description       = "Workspace → SOA DB"
  ip_protocol       = "TCP"
  from_port         = 1521
  to_port           = 1521
  cidr_ipv4         = local.application_data.accounts[local.environment].aws_workspace_cidr
}

resource "aws_security_group_rule" "soa_db_egress_all" {
  security_group_id = aws_security_group.soa_db.id
  type              = "egress"
  description       = "Allow all outbound"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

############################################################
# TDS DATABASE
############################################################
resource "aws_security_group" "tds_db" {
  name        = "ccms-soa-tds-allow-db"
  description = "Allow inbound for TDS DB"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_ingress_rule" "tds_db_ingress" {
  count             = length(local.private_subnets_cidr_blocks)
  security_group_id = aws_security_group.tds_db.id
  description       = "Internal → TDS DB"
  ip_protocol       = "TCP"
  from_port         = 1521
  to_port           = 1521
  cidr_ipv4         = local.private_subnets_cidr_blocks[count.index]
}

resource "aws_vpc_security_group_ingress_rule" "tds_db_workspace_ingress" {
  security_group_id = aws_security_group.tds_db.id
  description       = "Workspace → TDS DB"
  ip_protocol       = "TCP"
  from_port         = 1521
  to_port           = 1521
  cidr_ipv4         = local.application_data.accounts[local.environment].aws_workspace_cidr
}

resource "aws_security_group_rule" "tds_db_egress_all" {
  security_group_id = aws_security_group.tds_db.id
  type              = "egress"
  description       = "Allow all outbound"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

############################################################
# EFS
############################################################
resource "aws_security_group" "efs-security-group" {
  name_prefix = "${local.application_name}-efs-security-group"
  description = "EFS access for container instances"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_ingress_rule" "efs-security-group-ingress" {
  count             = length(local.private_subnets_cidr_blocks)
  description       = "Allow container → EFS"
  security_group_id = aws_security_group.efs-security-group.id
  ip_protocol       = "tcp"
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = local.private_subnets_cidr_blocks[count.index]
}

resource "aws_vpc_security_group_egress_rule" "efs-security-group-egress" {
  description       = "Allow all outbound"
  security_group_id = aws_security_group.efs-security-group.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

############################################################
# OEM CONNECTIVITY FOR SOA RDS
############################################################

# OMS host → SOA DB (1521, 3872, 4903)
resource "aws_vpc_security_group_ingress_rule" "soa_db_oem_oms_ingress_1521" {
  security_group_id = aws_security_group.soa_db.id
  description       = "OEM OMS → SOA RDS (1521)"
  ip_protocol       = "TCP"
  from_port         = 1521
  to_port           = 1521
  cidr_ipv4         = "10.26.60.231/32"
}

resource "aws_vpc_security_group_ingress_rule" "soa_db_oem_oms_ingress_3872" {
  security_group_id = aws_security_group.soa_db.id
  description       = "OEM OMS → SOA RDS (3872)"
  ip_protocol       = "TCP"
  from_port         = 3872
  to_port           = 3872
  cidr_ipv4         = "10.26.60.231/32"
}

resource "aws_vpc_security_group_ingress_rule" "soa_db_oem_oms_ingress_4903" {
  security_group_id = aws_security_group.soa_db.id
  description       = "OEM OMS → SOA RDS (4903)"
  ip_protocol       = "TCP"
  from_port         = 4903
  to_port           = 4903
  cidr_ipv4         = "10.26.60.231/32"
}

# OEM DB → SOA DB (1521)
resource "aws_vpc_security_group_ingress_rule" "soa_db_oem_db_ingress_1521" {
  security_group_id = aws_security_group.soa_db.id
  description       = "OEM DB → SOA RDS (1521)"
  ip_protocol       = "TCP"
  from_port         = 1521
  to_port           = 1521
  cidr_ipv4         = "10.26.60.169/32"
}
