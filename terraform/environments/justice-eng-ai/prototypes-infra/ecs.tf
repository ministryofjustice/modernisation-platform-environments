moved {
  from = aws_security_group.app
  to   = aws_security_group.app[0]
}

# Needs the shared edge's ALB, so it exists only where the edge does.
resource "aws_security_group" "app" {
  count = local.prototype_edge_enabled ? 1 : 0

  name        = "${local.application_name}-prototypes-app"
  description = "Allow traffic from the ALB security group on port 3000"
  vpc_id      = data.aws_vpc.vpc.id
  tags        = local.tags

  ingress {
    description     = "Allow traffic from ALB on port 3000"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [module.shared-prototype-edge[0].hosting.alb_security_group_id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "app" {
  name = "${local.application_name}-prototypes-app"
  tags = local.tags

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

