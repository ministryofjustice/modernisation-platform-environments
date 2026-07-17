resource "aws_security_group" "cluster" {
  name_prefix = "ecs-cluster-${local.environment}"
  vpc_id      = local.account_config.shared_vpc_id
  description = "ECS cluster SG"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ecs_service" {
  name        = "vcms-ecs"
  description = "Security group for ECS service"
  vpc_id      = local.account_info.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# Security group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = local.account_info.vpc_id

  dynamic "ingress" {
    for_each = local.internal_security_group_cidrs
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_security_group_rule" "ecs_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"

  security_group_id        = aws_security_group.ecs_service.id
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "alb_from_ecs" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"

  security_group_id        = aws_security_group.alb_sg.id
  source_security_group_id = aws_security_group.ecs_service.id
}