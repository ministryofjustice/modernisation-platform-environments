### Load Balancer Security Group

resource "aws_security_group" "load_balancer" {
  name_prefix = "${local.application_name}-load-balancer-sg"
  description = "Controls access to ${local.application_name} lb"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-lb-sg", local.application_name, local.environment)) }
  )
}

resource "aws_vpc_security_group_ingress_rule" "alb_ingress_443" {
  security_group_id = aws_security_group.load_balancer.id

  cidr_ipv4   = "0.0.0.0/0"
  description = "HTTPS from Anywhere - WAF in front of ALB"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

resource "aws_security_group_rule" "alb_egress_targets" {
  security_group_id = aws_security_group.load_balancer.id
  type              = "egress"
  description       = "Allow ALB outbound traffic to protected subnets"
  protocol          = "tcp"
  from_port         = 8080
  to_port           = 8080
  cidr_blocks = [
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block,
  ]
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

resource "aws_security_group_rule" "ecs_tasks_egress_443" {
  security_group_id = aws_security_group.ecs_tasks_pui.id
  type              = "egress"
  description       = "Allow ECS task egress to 0.0.0.0/0 on HTTPS"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ecs_tasks_egress_1522" {
  security_group_id = aws_security_group.ecs_tasks_pui.id
  type              = "egress"
  description       = "Allow ECS task egress to 0.0.0.0/0 on port 1522"
  protocol          = "tcp"
  from_port         = 1522
  to_port           = 1522
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ecs_tasks_egress_1521" {
  security_group_id = aws_security_group.ecs_tasks_pui.id
  type              = "egress"
  description       = "Allow ECS task egress to 0.0.0.0/0 on port 1521"
  protocol          = "tcp"
  from_port         = 1521
  to_port           = 1521
  cidr_blocks       = ["0.0.0.0/0"]
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

resource "aws_security_group_rule" "cluster_ec2_egress_443" {
  security_group_id = aws_security_group.cluster_ec2.id
  type              = "egress"
  description       = "Allow EC2 instance egress to 0.0.0.0/0 on HTTPS"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "cluster_ec2_egress_1522" {
  security_group_id = aws_security_group.cluster_ec2.id
  type              = "egress"
  description       = "Allow EC2 instance egress to 0.0.0.0/0 on port 1522"
  protocol          = "tcp"
  from_port         = 1522
  to_port           = 1522
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "cluster_ec2_egress_1521" {
  security_group_id = aws_security_group.cluster_ec2.id
  type              = "egress"
  description       = "Allow EC2 instance egress to 0.0.0.0/0 on port 1521"
  protocol          = "tcp"
  from_port         = 1521
  to_port           = 1521
  cidr_blocks       = ["0.0.0.0/0"]
}
