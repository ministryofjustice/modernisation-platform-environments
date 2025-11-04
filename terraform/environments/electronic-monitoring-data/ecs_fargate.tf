resource "aws_ecs_cluster" "this" {
  name = "ear-sars-ecs-cluster"
  tags =  merge(
    local.tags
  )
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }
}
