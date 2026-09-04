# Connector Load Balancer Security Group

resource "aws_security_group" "connector_load_balancer" {
  name_prefix = "${local.connector_app_name}-load-balancer-sg"
  description = "Controls access to ${local.connector_app_name} lb"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-lb-sg", local.connector_app_name)) }
  )
}

# HTTPS ingress from private subnets
resource "aws_vpc_security_group_ingress_rule" "connector_alb_ingress_443_a" {
  security_group_id = aws_security_group.connector_load_balancer.id
  cidr_ipv4         = data.aws_subnet.private_subnets_a.cidr_block
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS from private subnet A"
}

resource "aws_vpc_security_group_ingress_rule" "connector_alb_ingress_443_b" {
  security_group_id = aws_security_group.connector_load_balancer.id
  cidr_ipv4         = data.aws_subnet.private_subnets_b.cidr_block
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS from private subnet B"
}

resource "aws_vpc_security_group_ingress_rule" "connector_alb_ingress_443_c" {
  security_group_id = aws_security_group.connector_load_balancer.id
  cidr_ipv4         = data.aws_subnet.private_subnets_c.cidr_block
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS from private subnet C"
}

resource "aws_vpc_security_group_ingress_rule" "connector_alb_ingress_workspace" {
  security_group_id = aws_security_group.connector_load_balancer.id
  cidr_ipv4         = local.application_data.accounts[local.environment].aws_workspace
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "AWS Workspace"
}

# Restricted outbound traffic to OIA EC2 instances
resource "aws_vpc_security_group_egress_rule" "connector_alb_egress_oia_ec2" {
  security_group_id            = aws_security_group.connector_load_balancer.id
  description                  = "Allow ALB egress to OIA EC2 instances on ephemeral ports"
  ip_protocol                  = "tcp"
  from_port                    = 32768
  to_port                      = 61000
  referenced_security_group_id = aws_security_group.cluster_ec2.id
}

# Container Security Group

resource "aws_security_group" "ecs_tasks_connector" {
  name_prefix = "${local.connector_app_name}-ecs-tasks-security-group"
  description = "Controls access to ${local.connector_app_name} containers"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-task-sg", local.connector_app_name)) }
  )
}

# Ingress from Connector ALB to ECS containers
resource "aws_vpc_security_group_ingress_rule" "ecs_tasks_connector_ingress" {
  security_group_id            = aws_security_group.ecs_tasks_connector.id
  referenced_security_group_id = aws_security_group.connector_load_balancer.id
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].connector_server_port
  to_port                      = local.application_data.accounts[local.environment].connector_server_port
  description                  = "Allow ALB to reach Connector container port"
}

# Ingress from OIA EC2 instances to ECS containers
# resource "aws_vpc_security_group_ingress_rule" "ecs_tasks_connector_ingress_ec2" {
#   security_group_id            = aws_security_group.ecs_tasks_connector.id
#   referenced_security_group_id = aws_security_group.cluster_ec2.id
#   ip_protocol                  = "tcp"
#   from_port                    = local.application_data.accounts[local.environment].connector_server_port
#   to_port                      = local.application_data.accounts[local.environment].connector_server_port
#   description                  = "Allow EC2 access to Connector container port"
# }

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_connector_egress_vpce" {
  for_each          = toset([
    data.aws_subnet.vpce_subnets_a.cidr_block,
    data.aws_subnet.vpce_subnets_b.cidr_block,
    data.aws_subnet.vpce_subnets_c.cidr_block,
  ])
  security_group_id = aws_security_group.ecs_tasks_connector.id
  description       = "Allow egress to VPC endpoints (logs/ecs/secrets)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_connector_egress_s3" {
  security_group_id = aws_security_group.ecs_tasks_connector.id
  description       = "Allow S3 access via gateway endpoint (prefix list)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = data.aws_prefix_list.s3.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_connector_egress_443" {
  for_each          = toset([
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
  ])
  security_group_id = aws_security_group.ecs_tasks_connector.id
  description       = "HTTPS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_connector_egress_1521" {
  for_each          = toset([
    data.aws_subnet.data_subnets_a.cidr_block,
    data.aws_subnet.data_subnets_b.cidr_block,
    data.aws_subnet.data_subnets_c.cidr_block,
  ])
  security_group_id = aws_security_group.ecs_tasks_connector.id
  description       = "Allow egress to protected subnets"
  ip_protocol       = "tcp"
  from_port         = 1521
  to_port           = 1521
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_connector_egress_1522" {
  for_each          = toset([
    data.aws_subnet.data_subnets_a.cidr_block,
    data.aws_subnet.data_subnets_b.cidr_block,
    data.aws_subnet.data_subnets_c.cidr_block,
  ])
  security_group_id = aws_security_group.ecs_tasks_connector.id
  description       = "Allow egress to protected subnets on port 1522"
  ip_protocol       = "tcp"
  from_port         = 1522
  to_port           = 1522
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_connector_egress_2049_efs" {
  security_group_id            = aws_security_group.ecs_tasks_connector.id
  description                  = "Allow egress to EFS security group on port 2049"
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  referenced_security_group_id = aws_security_group.oia-efs-security-group.id
}