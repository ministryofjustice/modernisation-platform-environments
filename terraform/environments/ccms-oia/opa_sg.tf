# OPAHUB Load Balancer Security Group

resource "aws_security_group" "opahub_load_balancer" {
  name_prefix = "${local.opa_app_name}-load-balancer-sg"
  description = "Controls access to ${local.opa_app_name} lb"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-lb-sg", local.opa_app_name)) }
  )
}

# # Temp only for DEV
resource "aws_vpc_security_group_ingress_rule" "alb_ingress_7001_all" {
  count             = local.is-development ? 1 : 0
  security_group_id = aws_security_group.opahub_load_balancer.id
  cidr_ipv4         = local.application_data.accounts[local.environment].aws_workspace
  ip_protocol       = "tcp"
  from_port         = 7001
  to_port           = 7001
  description       = "7001 from AWS Workspaces"
}

# # Temp only for DEV
resource "aws_vpc_security_group_ingress_rule" "alb_ingress_7001_preproduction_all" {
  count             = local.is-preproduction ? 1 : 0
  security_group_id = aws_security_group.opahub_load_balancer.id
  cidr_ipv4         = local.application_data.accounts[local.environment].aws_workspace
  ip_protocol       = "tcp"
  from_port         = 7001
  to_port           = 7001
  description       = "7001 from AWS Workspaces"
}

resource "aws_security_group_rule" "alb_ingress_443_private_subnets" {
  security_group_id = aws_security_group.opahub_load_balancer.id
  type              = "ingress"
  description       = "HTTPS from private subnets"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks = [
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
  ]
}

resource "aws_security_group_rule" "alb_ingress_443_production_cidr" {
  count             = local.is-production ? 1 : 0
  security_group_id = aws_security_group.opahub_load_balancer.id
  type              = "ingress"
  description       = "HTTPS from production CIDR"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["172.31.192.0/18"]
}

resource "aws_security_group_rule" "alb_ingress_443_workspace" {
  security_group_id = aws_security_group.opahub_load_balancer.id
  type              = "ingress"
  description       = "HTTPS from AWS Workspaces"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [local.application_data.accounts[local.environment].aws_workspace]
}

resource "aws_security_group_rule" "alb_egress_oia_ec2" {
  security_group_id        = aws_security_group.opahub_load_balancer.id
  type                     = "egress"
  description              = "Allow ALB egress to OIA EC2 instances on ephemeral ports"
  protocol                 = "tcp"
  from_port                = 32768
  to_port                  = 61000
  source_security_group_id = aws_security_group.cluster_ec2.id
}


# Container Security Group

resource "aws_security_group" "ecs_tasks_opa" {
  name_prefix = "${local.opa_app_name}-ecs-tasks-security-group"
  description = "Controls access to ${local.opa_app_name} containers"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-task-sg", local.opa_app_name)) }
  )
}

resource "aws_vpc_security_group_ingress_rule" "ecs_tasks_opa_ingress" {
  security_group_id            = aws_security_group.ecs_tasks_opa.id
  referenced_security_group_id = aws_security_group.opahub_load_balancer.id
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].opa_server_port
  to_port                      = local.application_data.accounts[local.environment].opa_server_port
  description                  = "Allow ALB to reach ECS app port"
}

resource "aws_security_group_rule" "ecs_tasks_opa_egress_vpce" {
  security_group_id = aws_security_group.ecs_tasks_opa.id
  type              = "egress"
  description       = "Allow egress to VPC endpoints (logs/ecs/secrets)"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks = [
    data.aws_subnet.vpce_subnets_a.cidr_block,
    data.aws_subnet.vpce_subnets_b.cidr_block,
    data.aws_subnet.vpce_subnets_c.cidr_block,
  ]
}

resource "aws_security_group_rule" "ecs_tasks_opa_egress_s3" {
  security_group_id = aws_security_group.ecs_tasks_opa.id
  type              = "egress"
  description       = "Allow S3 access via gateway endpoint (prefix list)"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_ids   = [data.aws_prefix_list.s3.id]
}

resource "aws_security_group_rule" "ecs_tasks_opa_egress_443" {
  security_group_id = aws_security_group.ecs_tasks_opa.id
  type              = "egress"
  description       = "HTTPS"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks = [
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
  ]
}

resource "aws_security_group_rule" "ecs_tasks_opa_egress_mysql" {
  security_group_id = aws_security_group.ecs_tasks_opa.id
  type              = "egress"
  description       = "MySQL"
  protocol          = "tcp"
  from_port         = 3306
  to_port           = 3306
  cidr_blocks = [
    data.aws_subnet.data_subnets_a.cidr_block,
    data.aws_subnet.data_subnets_b.cidr_block,
    data.aws_subnet.data_subnets_c.cidr_block
  ]
}
resource "aws_security_group_rule" "ecs_tasks_opa_egress_1521" {
  security_group_id = aws_security_group.ecs_tasks_opa.id
  type              = "egress"
  description       = "Allow egress to protected subnets"
  protocol          = "tcp"
  from_port         = 1521
  to_port           = 1521
  cidr_blocks = [
    data.aws_subnet.data_subnets_a.cidr_block,
    data.aws_subnet.data_subnets_b.cidr_block,
    data.aws_subnet.data_subnets_c.cidr_block,
  ]
}

resource "aws_security_group_rule" "ecs_tasks_opa_egress_1522" {
  security_group_id = aws_security_group.ecs_tasks_opa.id
  type              = "egress"
  description       = "Allow egress to protected subnets on port 1522"
  protocol          = "tcp"
  from_port         = 1522
  to_port           = 1522
  cidr_blocks = [
    data.aws_subnet.data_subnets_a.cidr_block,
    data.aws_subnet.data_subnets_b.cidr_block,
    data.aws_subnet.data_subnets_c.cidr_block,
  ]
}

resource "aws_security_group_rule" "ecs_tasks_opa_egress_2049_efs" {
  security_group_id        = aws_security_group.ecs_tasks_opa.id
  type                     = "egress"
  description              = "Allow egress to EFS security group on port 2049"
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
  source_security_group_id = aws_security_group.oia-efs-security-group.id
}


# RDS Security Group

resource "aws_security_group" "opahub_db" {
  name        = "${local.opa_app_name}-mysql-db"
  description = "Allow MySQL DB inbound traffic"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-mysql-sg", local.opa_app_name)) }
  )
}

# Ingress from AWS Workspaces
resource "aws_vpc_security_group_ingress_rule" "opahub_db_ingress_workspaces" {
  security_group_id = aws_security_group.opahub_db.id
  cidr_ipv4         = local.application_data.accounts[local.environment].aws_workspace
  ip_protocol       = "tcp"
  from_port         = 3306
  to_port           = 3306
  description       = "Allow MySQL access from Workspaces"
}

# Ingress from ECS Cluster EC2s
resource "aws_vpc_security_group_ingress_rule" "opahub_db_ingress_ec2" {
  security_group_id            = aws_security_group.opahub_db.id
  referenced_security_group_id = aws_security_group.cluster_ec2.id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  description                  = "Allow MySQL access from ECS Cluster EC2s"
}

# # Allow all outbound
# resource "aws_vpc_security_group_egress_rule" "opahub_db_egress_all" {
#   security_group_id = aws_security_group.opahub_db.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1"
#   description       = "Allow all outbound traffic"
# }
