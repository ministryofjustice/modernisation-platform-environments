### Load Balancer Security Group

resource "aws_security_group" "load_balancer" {
  name_prefix = "${local.application_name}-load-balancer-sg"
  description = "Controls access to ${local.application_name} lb"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-lb-sg", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "alb_ingress_443" {
  security_group_id = aws_security_group.load_balancer.id
  type              = "ingress"
  description       = "HTTPS"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
}

resource "aws_security_group_rule" "alb_ingress_443_workspace" {
  security_group_id = aws_security_group.load_balancer.id
  type              = "ingress"
  description       = "HTTPS"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = [local.application_data.accounts[local.environment].aws_workspace]
}


resource "aws_security_group_rule" "alb_egress_all" {
  security_group_id = aws_security_group.load_balancer.id
  type              = "egress"
  description       = "All"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
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

resource "aws_security_group_rule" "ecs_tasks_pui" {
  security_group_id        = aws_security_group.ecs_tasks_pui.id
  type                     = "ingress"
  description              = "PUI Server Port"
  protocol                 = "TCP"
  from_port                = local.application_data.accounts[local.environment].pui_server_port
  to_port                  = local.application_data.accounts[local.environment].pui_server_port
  source_security_group_id = aws_security_group.load_balancer.id
}

resource "aws_security_group_rule" "ecs_tasks_egress_all" {
  security_group_id = aws_security_group.ecs_tasks_pui.id
  type              = "egress"
  description       = "All"
  protocol          = -1
  from_port         = 0
  to_port           = 0
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

resource "aws_security_group_rule" "cluster_ec2_ingress_22" {
  security_group_id = aws_security_group.cluster_ec2.id
  type              = "ingress"
  description       = "SSH"
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = [local.application_data.accounts[local.environment].aws_workspace]
}

resource "aws_security_group_rule" "cluster_ec2_ingress_lb" {
  security_group_id        = aws_security_group.cluster_ec2.id
  type                     = "ingress"
  description              = "Application Traffic"
  protocol                 = "TCP"
  from_port                = 0
  to_port                  = 65535
  source_security_group_id = aws_security_group.load_balancer.id # Allow the LB to access the EC2 instances
}

resource "aws_security_group_rule" "cluster_ec2_egress_all" {
  security_group_id = aws_security_group.cluster_ec2.id
  type              = "egress"
  description       = "All Egress"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"] # Restrict to what's needed
}