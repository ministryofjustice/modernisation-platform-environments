# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = local.first_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster" "additional" {
  name = local.second_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.capacity_provider_main.name]
}

resource "aws_ecs_cluster_capacity_providers" "additional" {
  cluster_name       = aws_ecs_cluster.additional.name
  capacity_providers = [aws_ecs_capacity_provider.capacity_provider_additional.name]
}