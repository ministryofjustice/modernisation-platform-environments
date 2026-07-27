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

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

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

resource "aws_security_group_rule" "alb_from_ecs" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"

  security_group_id        = aws_security_group.alb_sg.id
  source_security_group_id = aws_security_group.ecs_service.id
}

resource "aws_security_group" "mariadb" {
  name        = "rds-mariadb-sg"
  description = "SG for mariadb"
  vpc_id      = local.account_info.vpc_id

  ingress {
    description     = "MySQL from ECS tasks"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_security_group" "redis_sg" {
  name        = "redis-sg"
  description = "allow access to Redis"
  vpc_id      = local.account_info.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "efs" {
  name        = "vcms-${local.environment}-efs"
  description = "Allow traffic between vcms service and efs"
  vpc_id      = local.account_info.vpc_id

  tags = merge(
    local.tags,
    {
      Name = "vcms-efs-${local.environment}"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "efs_ingress_vpc" {
  security_group_id = aws_security_group.efs.id
  description       = "ingress vpc rules"

  type        = "ingress"
  from_port   = 2049
  to_port     = 2049
  protocol    = "tcp"
  cidr_blocks = [local.account_config.shared_vpc_cidr]
}

resource "aws_security_group_rule" "efs_egress_vpc" {
  security_group_id = aws_security_group.efs.id
  description       = "egress vpc rules"

  type        = "egress"
  from_port   = 2049
  to_port     = 2049
  protocol    = "tcp"
  cidr_blocks = [local.account_config.shared_vpc_cidr]
}
