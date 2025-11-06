### Load Balancer Security Group

resource "aws_security_group" "load_balancer" {
  name_prefix = "${local.application_name}-load-balancer-sg"
  description = "Controls access to ${local.application_name} lb"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-lb-sg", local.application_name, local.environment)) }
  )
}

resource "aws_vpc_security_group_ingress_rule" "alb_ingress_443_shared_vpc" {
  count = local.environment == "development" ? 1 : 0

  security_group_id = aws_security_group.load_balancer.id

  cidr_ipv4   = data.aws_vpc.shared.cidr_block
  description = "HTTPS from shared VPC"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

resource "aws_vpc_security_group_ingress_rule" "alb_ingress_443_secure_browser_vpc" {
  count = local.environment == "production" ? 1 : 0

  security_group_id = aws_security_group.load_balancer.id

  cidr_ipv4   = "172.31.192.0/18"
  description = "HTTPS from secure browser VPC"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

resource "aws_vpc_security_group_egress_rule" "alb_egress_all" {
  security_group_id = aws_security_group.load_balancer.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
}

### Container Security Group

resource "aws_security_group" "ecs_tasks_pui" {
  name_prefix = "${local.application_name}-ecs-tasks-security-group"
  description = "Controls access to ${local.application_name} containers"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-task-sg", local.application_name, local.environment)) }
  )
}

resource "aws_vpc_security_group_ingress_rule" "ecs_tasks_pui" {
  security_group_id            = aws_security_group.ecs_tasks_pui.id
  description                  = "PUI ALB into ECS tasks"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].pui_server_port
  to_port                      = local.application_data.accounts[local.environment].pui_server_port
  referenced_security_group_id = aws_security_group.load_balancer.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_tasks_egress_all" {
  security_group_id = aws_security_group.ecs_tasks_pui.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
}


# EC2 Instances Security Group
resource "aws_security_group" "cluster_ec2" {
  name        = "${local.application_name}-cluster-ec2-security-group"
  description = "Controls access to the cluster ec2 instance"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-ec2-sg", local.application_name, local.environment)) }
  )
}

resource "aws_vpc_security_group_egress_rule" "cluster_ec2_egress_all" {
  security_group_id = aws_security_group.cluster_ec2.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
}
