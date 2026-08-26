resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = module.ecs.ecs_cluster_name

  capacity_providers = [
    "FARGATE",
    "FARGATE_SPOT",
    aws_ecs_capacity_provider.weblogic.name,
    aws_ecs_capacity_provider.weblogic_eis.name
  ]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}