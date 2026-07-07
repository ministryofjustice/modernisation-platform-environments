data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${data.aws_region.current.name}.s3"
}

# ALB Security Group

resource "aws_security_group" "alb" {
  name        = "${local.component_name}-${local.env_label}-alb-sg"
  description = "Controls access to the ${local.component_name} application load balancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-alb-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_private_subnets" {
  for_each = toset(local.private_subnets_cidr_blocks)

  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from private subnets"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_northgate" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from Northgate proxy"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = local.application_data.accounts[local.environment].northgate_proxy
}

resource "aws_vpc_security_group_egress_rule" "alb_egress_ec2" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Allow LB to reach EC2 cluster ephemeral ports"
  ip_protocol                  = "tcp"
  from_port                    = 32768
  to_port                      = 61000
  referenced_security_group_id = aws_security_group.cluster_ec2.id
}

# ECS Tasks Security Group

resource "aws_security_group" "ecs_tasks" {
  name        = "${local.component_name}-${local.env_label}-ecs-tasks-sg"
  description = "Controls access to ${local.component_name} ECS containers"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-ecs-tasks-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "ecs_tasks_from_alb" {
  security_group_id            = aws_security_group.ecs_tasks.id
  description                  = "Traffic from ALB on application port"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].edrms_server_port
  to_port                      = local.application_data.accounts[local.environment].edrms_server_port
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_egress_vpce" {
  for_each = {
    a = data.aws_subnet.vpce_subnets_a.cidr_block
    b = data.aws_subnet.vpce_subnets_b.cidr_block
    c = data.aws_subnet.vpce_subnets_c.cidr_block
  }

  security_group_id = aws_security_group.ecs_tasks.id
  description       = "Allow egress to VPC endpoints (S3 / Secrets Manager)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_egress_s3" {
  security_group_id = aws_security_group.ecs_tasks.id
  description       = "Allow S3 access via gateway endpoint"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = data.aws_prefix_list.s3.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_egress_db" {
  security_group_id            = aws_security_group.ecs_tasks.id
  description                  = "Allow outbound DB access to TDS"
  ip_protocol                  = "tcp"
  from_port                    = 1521
  to_port                      = 1521
  referenced_security_group_id = aws_security_group.rds.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_egress_northgate_443" {
  security_group_id = aws_security_group.ecs_tasks.id
  description       = "Allow outbound HTTPS to Northgate proxy"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = local.application_data.accounts[local.environment].northgate_proxy
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_egress_northgate_80" {
  security_group_id = aws_security_group.ecs_tasks.id
  description       = "Allow outbound HTTP to Northgate proxy"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = local.application_data.accounts[local.environment].northgate_proxy
}

# EC2 Cluster Security Group

resource "aws_security_group" "cluster_ec2" {
  name        = "${local.component_name}-${local.env_label}-cluster-ec2-sg"
  description = "Controls access to the ${local.component_name} ECS cluster EC2 instances"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-cluster-ec2-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "cluster_ec2_ssh_workspace" {
  security_group_id = aws_security_group.cluster_ec2.id
  description       = "SSH from AWS workspace"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.application_data.accounts[local.environment].aws_workspace
}

resource "aws_vpc_security_group_ingress_rule" "cluster_ec2_from_alb" {
  security_group_id            = aws_security_group.cluster_ec2.id
  description                  = "Ephemeral port traffic from ALB"
  ip_protocol                  = "tcp"
  from_port                    = 32768
  to_port                      = 61000
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_vpce" {
  for_each = {
    a = data.aws_subnet.vpce_subnets_a.cidr_block
    b = data.aws_subnet.vpce_subnets_b.cidr_block
    c = data.aws_subnet.vpce_subnets_c.cidr_block
  }

  security_group_id = aws_security_group.cluster_ec2.id
  description       = "Allow egress to VPC endpoints (logs / ECS / Secrets Manager)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_s3" {
  security_group_id = aws_security_group.cluster_ec2.id
  description       = "Allow S3 access via gateway endpoint"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = data.aws_prefix_list.s3.id
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_db" {
  security_group_id            = aws_security_group.cluster_ec2.id
  description                  = "Allow outbound DB access to TDS"
  ip_protocol                  = "tcp"
  from_port                    = 1521
  to_port                      = 1521
  referenced_security_group_id = aws_security_group.rds.id
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_northgate_443" {
  security_group_id = aws_security_group.cluster_ec2.id
  description       = "Allow outbound HTTPS to Northgate proxy"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = local.application_data.accounts[local.environment].northgate_proxy
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_northgate_80" {
  security_group_id = aws_security_group.cluster_ec2.id
  description       = "Allow outbound HTTP to Northgate proxy"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = local.application_data.accounts[local.environment].northgate_proxy
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
  description       = "Oracle listener from private subnets"
  ip_protocol       = "tcp"
  from_port         = 1521
  to_port           = 1521
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_workspace" {
  security_group_id = aws_security_group.rds.id
  description       = "Oracle listener from AWS workspace"
  ip_protocol       = "tcp"
  from_port         = 1521
  to_port           = 1521
  cidr_ipv4         = local.application_data.accounts[local.environment].aws_workspace
}
