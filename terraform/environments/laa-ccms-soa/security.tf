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

#-- Tightened: ALB Admin egress restricted to ECS target port only (was 0.0.0.0/0 all-protocols)
resource "aws_vpc_security_group_egress_rule" "alb_admin_egress_ecs_targets" {
  count             = length(local.private_subnets_cidr_blocks)
  security_group_id = aws_security_group.alb_admin.id
  description       = "Egress to ECS Admin targets on WebLogic admin port"
  ip_protocol       = "tcp"
  from_port         = tonumber(local.application_data.accounts[local.environment].admin_server_port)
  to_port           = tonumber(local.application_data.accounts[local.environment].admin_server_port)
  cidr_ipv4         = local.private_subnets_cidr_blocks[count.index]
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

resource "aws_security_group_rule" "alb_managed_workspace_ingress_443" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "ingress"
  description       = "HTTPS - AWS Workspaces"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [local.application_data.accounts[local.environment].aws_workspace_cidr]
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

resource "aws_security_group_rule" "alb_managed_ingress_nec80" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "ingress"
  description       = "EM HTTP - NEC"
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = [local.application_data.accounts[local.environment].northgate_proxy]
}

resource "aws_security_group_rule" "alb_managed_ingress_nec443" {
  security_group_id = aws_security_group.alb_managed.id
  type              = "ingress"
  description       = "EM HTTPS - NEC"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [local.application_data.accounts[local.environment].northgate_proxy]
}

#-- Tightened: ALB Managed egress restricted to ECS target port only (was 0.0.0.0/0 all-protocols)
resource "aws_vpc_security_group_egress_rule" "alb_managed_egress_ecs_targets" {
  count             = length(local.private_subnets_cidr_blocks)
  security_group_id = aws_security_group.alb_managed.id
  description       = "Egress to ECS Managed targets on WebLogic managed port"
  ip_protocol       = "tcp"
  from_port         = tonumber(local.application_data.accounts[local.environment].managed_server_port)
  to_port           = tonumber(local.application_data.accounts[local.environment].managed_server_port)
  cidr_ipv4         = local.private_subnets_cidr_blocks[count.index]
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

#-- Tightened: ECS Admin egress - all required outbound rules
#-- 1) VPC Interface Endpoints: ECR (api+dkr), CloudWatch Logs, SSM, SecretsManager (all tcp/443)
#--    S3 is a Gateway endpoint - no SG rule needed, handled via route table.
#--    EBS NLB (tcp/443, private subnets) is also covered by this rule.
resource "aws_vpc_security_group_egress_rule" "ecs_tasks_admin_egress_vpc_endpoints" {
  count             = length(local.private_subnets_cidr_blocks)
  security_group_id = aws_security_group.ecs_tasks_admin.id
  description       = "VPC Interface Endpoints + EBS NLB - ECR, CloudWatch, SSM, SecretsManager (tcp/443)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = local.private_subnets_cidr_blocks[count.index]
}

#-- 2) Oracle DB connections: SOA DB (data subnets, this VPC) and TDS DB (EDRMS account, cross-account).
#--    Using 0.0.0.0/0 as interim because EDRMS data subnet CIDRs are in a separate account.
#--    TODO: once EDRMS data subnet CIDRs are confirmed via VPC peering config, replace 0.0.0.0/0
#--    with two separate rules: one for local data_subnets_cidr_blocks and one for EDRMS CIDRs.
resource "aws_vpc_security_group_egress_rule" "ecs_tasks_admin_egress_oracle" {
  security_group_id = aws_security_group.ecs_tasks_admin.id
  description       = "Oracle DB (tcp/1521) - SOA DB and TDS DB. TODO: tighten CIDR when EDRMS data subnets confirmed"
  ip_protocol       = "tcp"
  from_port         = 1521
  to_port           = 1521
  cidr_ipv4         = "0.0.0.0/0"
}

#-- 3) WebLogic Admin→Managed Server communication (T3 protocol on managed_server_port/8001).
resource "aws_vpc_security_group_egress_rule" "ecs_tasks_admin_egress_managed_server" {
  count             = length(local.private_subnets_cidr_blocks)
  security_group_id = aws_security_group.ecs_tasks_admin.id
  description       = "WebLogic Admin to Managed Server T3 comms (tcp/8001)"
  ip_protocol       = "tcp"
  from_port         = tonumber(local.application_data.accounts[local.environment].managed_server_port)
  to_port           = tonumber(local.application_data.accounts[local.environment].managed_server_port)
  cidr_ipv4         = local.private_subnets_cidr_blocks[count.index]
}

#-- 4) CWA (ECP) DB datasource - external Oracle DB used for the EBS SMS composites.
#--    Port is environment-specific: 1571 (non-prod) / 2484 (prod, TCPS).
#--    Using 0.0.0.0/0 as interim. TODO: tighten to specific CWA DB IP from VPC Flow Logs.
resource "aws_vpc_security_group_egress_rule" "ecs_tasks_admin_egress_cwa_db" {
  security_group_id = aws_security_group.ecs_tasks_admin.id
  description       = "CWA (ECP) Oracle DB - EBS SMS datasource. TODO: tighten to specific IP from VPC flow logs"
  ip_protocol       = "tcp"
  from_port         = tonumber(local.application_data.accounts[local.environment].cwa_db_port)
  to_port           = tonumber(local.application_data.accounts[local.environment].cwa_db_port)
  cidr_ipv4         = "0.0.0.0/0"
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

#-- Tightened: ECS Managed egress - all required outbound rules
#-- 1) VPC Interface Endpoints: ECR (api+dkr), CloudWatch Logs, SSM, SecretsManager (all tcp/443)
#--    S3 is a Gateway endpoint - no SG rule needed, handled via route table.
resource "aws_vpc_security_group_egress_rule" "ecs_tasks_managed_egress_vpc_endpoints" {
  count             = length(local.private_subnets_cidr_blocks)
  security_group_id = aws_security_group.ecs_tasks_managed.id
  description       = "VPC Interface Endpoints - ECR, CloudWatch, SSM, SecretsManager (tcp/443)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = local.private_subnets_cidr_blocks[count.index]
}

#-- 2) Benefit Checker on Cloud Platform.
#--    TODO: tighten cidr_ipv4 to a specific /32 once the exact IP is confirmed from VPC Flow Logs.
resource "aws_vpc_security_group_egress_rule" "ecs_tasks_managed_egress_benefit_checker" {
  security_group_id = aws_security_group.ecs_tasks_managed.id
  description       = "Benefit Checker HTTPS - Cloud Platform (tcp/443). TODO: tighten to /32 from VPC flow logs"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = local.application_data.accounts[local.environment].cloud_platform_cidr
}

#-- 3) Oracle DB connections: each Managed Server creates its own JDBC connection pool to the databases
#--    (SOA DB in data subnets, TDS DB in EDRMS account). Using 0.0.0.0/0 as interim.
#--    TODO: tighten to local data_subnets_cidr_blocks + EDRMS data subnet CIDRs when confirmed.
resource "aws_vpc_security_group_egress_rule" "ecs_tasks_managed_egress_oracle" {
  security_group_id = aws_security_group.ecs_tasks_managed.id
  description       = "Oracle DB (tcp/1521) - SOA DB and TDS DB. TODO: tighten CIDR when EDRMS data subnets confirmed"
  ip_protocol       = "tcp"
  from_port         = 1521
  to_port           = 1521
  cidr_ipv4         = "0.0.0.0/0"
}

#-- 4) WebLogic Managed→Admin Server communication (T3 protocol on admin_server_port/7001).
#--    Managed Servers register with and receive config from the Admin Server over T3.
resource "aws_vpc_security_group_egress_rule" "ecs_tasks_managed_egress_admin_server" {
  count             = length(local.private_subnets_cidr_blocks)
  security_group_id = aws_security_group.ecs_tasks_managed.id
  description       = "WebLogic Managed to Admin Server T3 comms (tcp/7001)"
  ip_protocol       = "tcp"
  from_port         = tonumber(local.application_data.accounts[local.environment].admin_server_port)
  to_port           = tonumber(local.application_data.accounts[local.environment].admin_server_port)
  cidr_ipv4         = local.private_subnets_cidr_blocks[count.index]
}

#--Cluster EC2 Instances
resource "aws_security_group" "cluster_ec2" {
  name        = "${local.application_data.accounts[local.environment].app_name}-cluster-ec2-security-group"
  description = "controls access to the cluster ec2 instance"
  vpc_id      = data.aws_vpc.shared.id
}

#-- Tightened: Cluster EC2 egress - all required outbound rules (was all-protocols 0.0.0.0/0)

#-- 1) HTTP/HTTPS to internet - required for OS package installs (yum/dnf) and ECS agent updates.
#--    tcp/443 also covers all VPC Interface Endpoints (ECR, CloudWatch, SSM, SecretsManager, ECS).
resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_http" {
  security_group_id = aws_security_group.cluster_ec2.id
  description       = "HTTP - OS and package installs (yum/dnf)"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_https" {
  security_group_id = aws_security_group.cluster_ec2.id
  description       = "HTTPS - package installs, ECS agent, and VPC Interface Endpoints (ECR, CloudWatch, SSM, SecretsManager)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_dns" {
  security_group_id = aws_security_group.cluster_ec2.id
  description       = "DNS resolution"
  ip_protocol       = "udp"
  from_port         = 53
  to_port           = 53
  cidr_ipv4         = "0.0.0.0/0"
}

#-- 2) EFS NFS mount - EC2 instances mount EFS at boot time (user_data). EFS mount targets are in
#--    data subnets. This is an EC2 host-level operation; the ECS task ENIs do not need this rule.
resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_efs" {
  count             = length(local.data_subnets_cidr_blocks)
  security_group_id = aws_security_group.cluster_ec2.id
  description       = "NFS to EFS mount targets in data subnets (tcp/2049)"
  ip_protocol       = "tcp"
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = local.data_subnets_cidr_blocks[count.index]
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

#-- Tightened: SOA DB egress (was all-protocols 0.0.0.0/0)

#-- 1) CloudWatch VPC Interface Endpoint - required for RDS Enhanced Monitoring and log streaming.
resource "aws_vpc_security_group_egress_rule" "soa_db_egress_cloudwatch" {
  count             = length(local.private_subnets_cidr_blocks)
  security_group_id = aws_security_group.soa_db.id
  description       = "CloudWatch VPC Interface Endpoint (RDS Enhanced Monitoring and log streaming)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = local.private_subnets_cidr_blocks[count.index]
}

#-- 2) OEM agent outbound to OMS upload port (tcp/4903).
#--    The OEM_AGENT RDS option installs an agent that must connect TO OMS on port 4903.
#--    This is separate from OMS→agent ingress on port 3872 which is already covered above.
resource "aws_vpc_security_group_egress_rule" "soa_db_egress_oem_agent" {
  security_group_id = aws_security_group.soa_db.id
  description       = "OEM agent outbound to OMS upload port (tcp/4903)"
  ip_protocol       = "tcp"
  from_port         = tonumber(local.application_data.accounts[local.environment].oem.oms_port)
  to_port           = tonumber(local.application_data.accounts[local.environment].oem.oms_port)
  cidr_ipv4         = local.application_data.accounts[local.environment].oem.oms_platform_cidr
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

## Dont need this block we can use the same variable key name with a production workspace cidr as done above
# resource "aws_vpc_security_group_ingress_rule" "tds_db_workspace_ingress_prod" {
#   count             = local.is-production ? 1 : 0
#   security_group_id = aws_security_group.tds_db.id
#   description       = "Workspace to Database Ingress"
#   ip_protocol       = "TCP"
#   from_port         = 1521
#   to_port           = 1521
#   cidr_ipv4         = local.application_data.accounts[local.environment].workspace_cidr_prod
# }

#-- Tightened: TDS DB egress restricted to Oracle port only (was all-protocols 0.0.0.0/0)
#-- Per Andy's spec: egress destination is EDRMS account data subnets (cross-account).
#-- These CIDRs are NOT in this repository - they belong to the EDRMS account.
#-- Using 0.0.0.0/0 as an interim on tcp/1521 only (still a significant reduction from all-protocols/all-ports).
#-- TODO: once EDRMS data subnet CIDRs are confirmed (via VPC peering config or EDRMS team),
#--       replace 0.0.0.0/0 with the specific EDRMS data subnet CIDRs.
resource "aws_vpc_security_group_egress_rule" "tds_db_egress_oracle" {
  security_group_id = aws_security_group.tds_db.id
  description       = "Oracle tcp/1521 to EDRMS account (cross-account). TODO: tighten CIDR to EDRMS data subnets"
  ip_protocol       = "tcp"
  from_port         = 1521
  to_port           = 1521
  cidr_ipv4         = "0.0.0.0/0"
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

#-- Tightened: EFS egress restricted to NFS (tcp/2049) to compute private subnets only (was all-protocols 0.0.0.0/0)
resource "aws_vpc_security_group_egress_rule" "efs-security-group-egress" {
  count             = length(local.private_subnets_cidr_blocks)
  description       = "NFS responses to compute instances in private subnets (tcp/2049)"
  security_group_id = aws_security_group.efs-security-group.id
  ip_protocol       = "tcp"
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = local.private_subnets_cidr_blocks[count.index]
}

# OEM OMS → SOA DB (OMS port 4903)
resource "aws_vpc_security_group_ingress_rule" "soa_db_oem_oms_ingress_4903" {
  security_group_id = aws_security_group.soa_db.id
  description       = "OEM OMS to SOA DB OMS port"
  ip_protocol       = "TCP"
  from_port         = tonumber(local.application_data.accounts[local.environment].oem.oms_port)
  to_port           = tonumber(local.application_data.accounts[local.environment].oem.oms_port)
  cidr_ipv4         = local.application_data.accounts[local.environment].oem.oms_platform_cidr
}

# OEM OMS → SOA DB (OEM agent 3872)
resource "aws_vpc_security_group_ingress_rule" "soa_db_oem_oms_ingress_3872" {
  security_group_id = aws_security_group.soa_db.id
  description       = "OEM OMS to SOA DB agent port"
  ip_protocol       = "TCP"
  from_port         = tonumber(local.application_data.accounts[local.environment].oem.agent_port)
  to_port           = tonumber(local.application_data.accounts[local.environment].oem.agent_port)
  cidr_ipv4         = local.application_data.accounts[local.environment].oem.oms_platform_cidr
}

# OEM OMS → SOA DB (Oracle listener 1521)
resource "aws_vpc_security_group_ingress_rule" "soa_db_oem_oms_ingress_1521" {
  security_group_id = aws_security_group.soa_db.id
  description       = "OEM OMS to SOA DB listener"
  ip_protocol       = "TCP"
  from_port         = tonumber(local.application_data.accounts[local.environment].oem.soa_db_port)
  to_port           = tonumber(local.application_data.accounts[local.environment].oem.soa_db_port)
  cidr_ipv4         = local.application_data.accounts[local.environment].oem.oms_platform_cidr
}

# OEM DB → SOA DB (Oracle listener 1521)
resource "aws_vpc_security_group_ingress_rule" "soa_db_oem_db_ingress_1521" {
  security_group_id = aws_security_group.soa_db.id
  description       = "OEM DB to SOA DB listener"
  ip_protocol       = "TCP"
  from_port         = tonumber(local.application_data.accounts[local.environment].oem.soa_db_port)
  to_port           = tonumber(local.application_data.accounts[local.environment].oem.soa_db_port)
  cidr_ipv4         = local.application_data.accounts[local.environment].oem.oem_db_platform_cidr
}
