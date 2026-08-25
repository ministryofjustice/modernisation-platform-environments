##############################################
### ECS Cluster for LinOTP 3.x + FreeRADIUS (Fargate)
##############################################

resource "aws_ecs_cluster" "workspaces" {
  name = "${local.application_name}-${local.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-ecs" }
  )
}

resource "aws_ecs_cluster_capacity_providers" "workspaces" {
  cluster_name       = aws_ecs_cluster.workspaces.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

resource "aws_cloudwatch_log_group" "ecs_linotp3" {
  name              = "/aws/ecs/${local.application_name}-${local.environment}-linotp3"
  retention_in_days = 30

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-ecs-linotp3-logs" }
  )
}
