#######################################
# ECS Cluster and Service for OIA
#######################################

# # Capacity Provider
# resource "aws_ecs_capacity_provider" "capacity_provider" {
#   name = "${local.application_name}-capacity-provider"

#   auto_scaling_group_provider {
#     auto_scaling_group_arn = aws_autoscaling_group.cluster_scaling_group.arn
#   }

#   tags = merge(local.tags,
#     { Name = lower(format("%s-%s-cp", local.application_name, local.environment)) }
#   )
# }

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${local.application_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.capacity_provider.name]
}

# ECS Task Definition
resource "aws_ecs_task_definition" "opahub" {
  family                   = "${local.opa_app_name}-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]

  cpu    = local.application_data.accounts[local.environment].opa_container_cpu
  memory = local.application_data.accounts[local.environment].opa_container_memory

  container_definitions = templatefile(
    "${path.module}/templates/task_definition_opahub.json.tpl",
    {
      app_name          = local.application_name
      app_image         = local.application_data.accounts[local.environment].app_image
      server_port       = local.application_data.accounts[local.environment].server_port
      aws_region        = local.application_data.accounts[local.environment].aws_region
      container_version = local.application_data.accounts[local.environment].container_version
      opahub_password   = aws_secretsmanager_secret.opahub_password.arn
      db_host           = local.application_data.accounts[local.environment].db_host
      db_user           = local.application_data.accounts[local.environment].db_user
      db_password       = aws_secretsmanager_secret.opahub_db_password.arn
      wl_user           = local.application_data.accounts[local.environment].wl_user
      wl_password       = aws_secretsmanager_secret.wl_password.arn
      wl_mem_args       = local.application_data.accounts[local.environment].wl_mem_args
      secret_key        = aws_secretsmanager_secret.secret_key.arn
    }
  )

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-task", local.opa_app_name, local.environment)) }
  )
}

# ECS Service
resource "aws_ecs_service" "opahub" {
  name            = local.opa_app_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.opahub.arn
  desired_count   = local.application_data.accounts[local.environment].opa_app_count
  launch_type     = "EC2"

  health_check_grace_period_seconds = 120

  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.opahub_target_group.id
    container_name   = local.opa_app_name
    container_port   = local.application_data.accounts[local.environment].opa_app_port
  }

  depends_on = [
    aws_lb_listener.opahub,
    aws_iam_role_policy_attachment.ecs_task_execution_role,
    aws_autoscaling_group.cluster_scaling_group
  ]
}
