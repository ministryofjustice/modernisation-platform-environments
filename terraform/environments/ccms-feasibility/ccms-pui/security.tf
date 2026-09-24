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

resource "aws_vpc_security_group_ingress_rule" "alb_https_workspace" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from AWS workspace"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = local.application_data.accounts[local.environment].aws_workspace
}

resource "aws_vpc_security_group_egress_rule" "alb_egress_ecs_tasks" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Allow LB to reach the ECS tasks on the application port"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].pui_server_port
  to_port                      = local.application_data.accounts[local.environment].pui_server_port
  referenced_security_group_id = aws_security_group.ecs_tasks.id
}

# ECS Task Security Group (awsvpc mode - attached to the task ENI)

resource "aws_security_group" "ecs_tasks" {
  name        = "${local.component_name}-${local.env_label}-ecs-tasks-sg"
  description = "Controls access to the ${local.component_name} ECS task ENIs"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-ecs-tasks-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "ecs_tasks_from_alb" {
  security_group_id            = aws_security_group.ecs_tasks.id
  description                  = "Application port from the ALB"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].pui_server_port
  to_port                      = local.application_data.accounts[local.environment].pui_server_port
  referenced_security_group_id = aws_security_group.alb.id
}


resource "aws_vpc_security_group_egress_rule" "ecs_tasks_egress_https" {
  security_group_id = aws_security_group.ecs_tasks.id
  description       = "Allow outbound HTTPS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_egress_db" {
  for_each = { for pair in setproduct(local.db_ports, local.data_subnets_cidr_blocks) : "${pair[0]}-${pair[1]}" => pair }

  security_group_id = aws_security_group.ecs_tasks.id
  description       = "Allow outbound to EBS DB in the data subnets"
  ip_protocol       = "tcp"
  from_port         = each.value[0]
  to_port           = each.value[0]
  cidr_ipv4         = each.value[1]
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_egress_clamav" {
  security_group_id            = aws_security_group.ecs_tasks.id
  description                  = "Allow outbound to ClamAV"
  ip_protocol                  = "tcp"
  from_port                    = 3310
  to_port                      = 3310
  referenced_security_group_id = data.aws_security_group.clamav.id
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

# ECS agent, ECR, SSM and CloudWatch over HTTPS
resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_https" {
  security_group_id = aws_security_group.cluster_ec2.id
  description       = "Allow outbound HTTPS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_db" {
  for_each = { for pair in setproduct(local.db_ports, local.data_subnets_cidr_blocks) : "${pair[0]}-${pair[1]}" => pair }

  security_group_id = aws_security_group.cluster_ec2.id
  description       = "Allow outbound to EBS DB in the data subnets"
  ip_protocol       = "tcp"
  from_port         = each.value[0]
  to_port           = each.value[0]
  cidr_ipv4         = each.value[1]
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_clamav" {
  security_group_id            = aws_security_group.cluster_ec2.id
  description                  = "Allow outbound to ClamAV"
  ip_protocol                  = "tcp"
  from_port                    = 3310
  to_port                      = 3310
  referenced_security_group_id = data.aws_security_group.clamav.id
}

# Shared ClamAV security group, managed in the ccms-feasibility root stack
data "aws_security_group" "clamav" {
  vpc_id = data.aws_vpc.shared.id
  name   = "${local.application_name}-clamav-sg"
}
