#######################################
# Load Balancer Security Group
#######################################

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
  cidr_blocks       = local.private_subnets_cidr_blocks
}

resource "aws_security_group_rule" "alb_egress_all" {
  security_group_id = aws_security_group.load_balancer.id
  type              = "egress"
  description       = "All outbound"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

#######################################
# Container Security Group
#######################################

resource "aws_security_group" "ecs_tasks_oia" {
  name_prefix = "${local.application_name}-ecs-tasks-security-group"
  description = "Controls access to ${local.application_name} containers"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-task-sg", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ecs_tasks_oia_ingress" {
  security_group_id        = aws_security_group.ecs_tasks_oia.id
  type                     = "ingress"
  description              = "OIA App Port"
  protocol                 = "TCP"
  from_port                = local.application_data.accounts[local.environment].app_port
  to_port                  = local.application_data.accounts[local.environment].app_port
  source_security_group_id = aws_security_group.load_balancer.id
}

resource "aws_security_group_rule" "ecs_tasks_oia_egress_all" {
  security_group_id = aws_security_group.ecs_tasks_oia.id
  type              = "egress"
  description       = "All outbound"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

#######################################
# EC2 Instances Security Group
#######################################

resource "aws_security_group" "cluster_ec2" {
  name        = "${local.application_name}-cluster-ec2-security-group"
  description = "Controls access to the cluster EC2 instances"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-ec2-sg", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "cluster_ec2_ingress_22" {
  security_group_id = aws_security_group.cluster_ec2.id
  type              = "ingress"
  description       = "SSH from private subnets"
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = local.private_subnets_cidr_blocks
}

resource "aws_security_group_rule" "cluster_ec2_ingress_lb" {
  security_group_id        = aws_security_group.cluster_ec2.id
  type                     = "ingress"
  description              = "Traffic from ALB"
  protocol                 = "TCP"
  from_port                = 0
  to_port                  = 65535
  source_security_group_id = aws_security_group.load_balancer.id
}

resource "aws_security_group_rule" "cluster_ec2_egress_all" {
  security_group_id = aws_security_group.cluster_ec2.id
  type              = "egress"
  description       = "All outbound"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

#######################################
# RDS Security Group
#######################################

resource "aws_security_group" "oia_db" {
  name        = "${local.application_name}-mysql-db"
  description = "Allow MySQL DB inbound traffic"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-mysql-sg", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "oia_db_ingress" {
  security_group_id        = aws_security_group.oia_db.id
  type                     = "ingress"
  description              = "MySQL access from ECS tasks"
  protocol                 = "TCP"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = aws_security_group.ecs_tasks_oia.id
}

resource "aws_security_group_rule" "oia_db_egress_all" {
  security_group_id = aws_security_group.oia_db.id
  type              = "egress"
  description       = "All outbound"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}
