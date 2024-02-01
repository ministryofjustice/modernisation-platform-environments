
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${local.application_name}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

