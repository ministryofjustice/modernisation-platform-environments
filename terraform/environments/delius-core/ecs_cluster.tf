# Commented out for time being while we discuss this module
# module "ecs-cluster" {
#   source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=f1ace6467418d0df61fd8ff6beabd1c028798d39"

#   environment = local.environment
#   name        = local.application_name

#   tags = local.tags
# }

resource "aws_ecs_cluster_capacity_providers" "ecs_cluser_capacity_providers" {
  cluster_name = aws_ecs_cluster.aws_ecs_cluster.name
  capacity_providers = [
    "FARGATE",
    "FARGATE_SPOT"
  ]
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = "1"
  }
}

resource "aws_ecs_cluster" "aws_ecs_cluster" {
  name = "delius-core"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = local.tags
}

