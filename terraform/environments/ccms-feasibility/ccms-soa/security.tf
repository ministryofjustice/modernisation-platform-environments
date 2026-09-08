# Admin NLB Security Group

resource "aws_security_group" "nlb_admin" {
  name        = "${local.component_name}-${local.env_label}-admin-nlb-sg"
  description = "Controls access to the ${local.component_name} admin load balancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-admin-nlb-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "nlb_admin_https_private" {
  for_each = toset(local.private_subnets_cidr_blocks)

  security_group_id = aws_security_group.nlb_admin.id
  description       = "HTTPS from private subnets"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "nlb_admin_ssl_port_private" {
  for_each = toset(local.private_subnets_cidr_blocks)

  security_group_id = aws_security_group.nlb_admin.id
  description       = "WebLogic admin SSL port from private subnets"
  ip_protocol       = "tcp"
  from_port         = local.application_data.accounts[local.environment].admin_ssl_port
  to_port           = local.application_data.accounts[local.environment].admin_ssl_port
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "nlb_admin_egress_ecs_tasks" {
  security_group_id            = aws_security_group.nlb_admin.id
  description                  = "Allow NLB to reach the admin ECS task"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].admin_ssl_port
  to_port                      = local.application_data.accounts[local.environment].admin_ssl_port
  referenced_security_group_id = aws_security_group.ecs_tasks_admin.id
}

# Managed NLB Security Group

resource "aws_security_group" "nlb_managed" {
  name        = "${local.component_name}-${local.env_label}-managed-nlb-sg"
  description = "Controls access to the ${local.component_name} managed load balancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-managed-nlb-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "nlb_managed_https_private" {
  for_each = toset(local.private_subnets_cidr_blocks)

  security_group_id = aws_security_group.nlb_managed.id
  description       = "HTTPS from private subnets"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "nlb_managed_ssl_port_private" {
  for_each = toset(local.private_subnets_cidr_blocks)

  security_group_id = aws_security_group.nlb_managed.id
  description       = "WebLogic managed SSL port from private subnets"
  ip_protocol       = "tcp"
  from_port         = local.application_data.accounts[local.environment].managed_ssl_port
  to_port           = local.application_data.accounts[local.environment].managed_ssl_port
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "nlb_managed_egress_ecs_tasks" {
  security_group_id            = aws_security_group.nlb_managed.id
  description                  = "Allow NLB to reach the managed ECS task"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].managed_ssl_port
  to_port                      = local.application_data.accounts[local.environment].managed_ssl_port
  referenced_security_group_id = aws_security_group.ecs_tasks_managed.id
}

# ECS Task Security Groups (awsvpc mode - one per service, attached to the task ENI)

resource "aws_security_group" "ecs_tasks_admin" {
  name        = "${local.component_name}-${local.env_label}-ecs-tasks-admin-sg"
  description = "Controls access to the ${local.component_name} admin ECS task ENIs"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-ecs-tasks-admin-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "ecs_tasks_admin_from_nlb_admin" {
  security_group_id            = aws_security_group.ecs_tasks_admin.id
  description                  = "Admin SSL port from the admin NLB"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].admin_ssl_port
  to_port                      = local.application_data.accounts[local.environment].admin_ssl_port
  referenced_security_group_id = aws_security_group.nlb_admin.id
}

resource "aws_vpc_security_group_ingress_rule" "ecs_tasks_admin_from_ecs_tasks_managed" {
  security_group_id            = aws_security_group.ecs_tasks_admin.id
  description                  = "Admin SSL port from the managed ECS task (WebLogic domain/cluster coordination)"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].admin_ssl_port
  to_port                      = local.application_data.accounts[local.environment].admin_ssl_port
  referenced_security_group_id = aws_security_group.ecs_tasks_managed.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_admin_egress_all" {
  security_group_id = aws_security_group.ecs_tasks_admin.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "ecs_tasks_managed" {
  name        = "${local.component_name}-${local.env_label}-ecs-tasks-managed-sg"
  description = "Controls access to the ${local.component_name} managed ECS task ENIs"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-ecs-tasks-managed-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "ecs_tasks_managed_from_nlb_managed" {
  security_group_id            = aws_security_group.ecs_tasks_managed.id
  description                  = "Managed SSL port from the managed NLB"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].managed_ssl_port
  to_port                      = local.application_data.accounts[local.environment].managed_ssl_port
  referenced_security_group_id = aws_security_group.nlb_managed.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_managed_egress_all" {
  security_group_id = aws_security_group.ecs_tasks_managed.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ECS Cluster EC2 Security Group (the underlying hosts)

resource "aws_security_group" "cluster_ec2" {
  name        = "${local.component_name}-${local.env_label}-cluster-ec2-sg"
  description = "Controls access to the ${local.component_name} ECS cluster EC2 instances"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-cluster-ec2-sg"
  })
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_all" {
  security_group_id = aws_security_group.cluster_ec2.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# RDS Security Group

resource "aws_security_group" "rds" {
  name        = "${local.component_name}-${local.env_label}-rds-sg"
  description = "Controls access to the ${local.component_name} Oracle RDS instance"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-rds-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_private_subnets" {
  for_each = toset(local.private_subnets_cidr_blocks)

  security_group_id = aws_security_group.rds.id
  description       = "Oracle from private subnets"
  ip_protocol       = "tcp"
  from_port         = 1521
  to_port           = 1521
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs_tasks_admin" {
  security_group_id            = aws_security_group.rds.id
  description                  = "Oracle from the admin ECS task (the only SOA task that talks to the DB)"
  ip_protocol                  = "tcp"
  from_port                    = 1521
  to_port                      = 1521
  referenced_security_group_id = aws_security_group.ecs_tasks_admin.id
}

resource "aws_vpc_security_group_egress_rule" "rds_egress_all" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# EFS Security Group

resource "aws_security_group" "efs" {
  name        = "${local.component_name}-${local.env_label}-efs-sg"
  description = "Controls NFS access to the ${local.component_name} EFS file system"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-efs-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "efs_from_ecs_tasks_admin" {
  security_group_id            = aws_security_group.efs.id
  description                  = "NFS from the admin ECS task"
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  referenced_security_group_id = aws_security_group.ecs_tasks_admin.id
}

resource "aws_vpc_security_group_ingress_rule" "efs_from_ecs_tasks_managed" {
  security_group_id            = aws_security_group.efs.id
  description                  = "NFS from the managed ECS task"
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  referenced_security_group_id = aws_security_group.ecs_tasks_managed.id
}

resource "aws_vpc_security_group_egress_rule" "efs_egress_all" {
  security_group_id = aws_security_group.efs.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
