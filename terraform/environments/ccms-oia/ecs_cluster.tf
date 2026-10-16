# ECS Cluster
resource "aws_ecs_cluster" "opa" {
  name = "${local.first_cluster_name}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster" "conn_saa" {
  name = "${local.second_cluster_name}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "opa" {
  cluster_name       = aws_ecs_cluster.opa.name
  capacity_providers = [aws_ecs_capacity_provider.capacity_provider_opa.name]
}

resource "aws_ecs_cluster_capacity_providers" "conn_saa" {
  cluster_name       = aws_ecs_cluster.conn_saa.name
  capacity_providers = [aws_ecs_capacity_provider.capacity_provider_conn_saa.name]
}