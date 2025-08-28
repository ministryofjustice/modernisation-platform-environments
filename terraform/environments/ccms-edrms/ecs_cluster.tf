# Capacity Providers

resource "aws_ecs_capacity_provider" "capacity-provider" {
  name = "${local.application_name}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.cluster-scaling-group.arn
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-cp", local.application_name, local.environment)) }
  )
}


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
  capacity_providers = [aws_ecs_capacity_provider.capacity-provider.name]
}

# ECS Task Definition


resource "aws_ecs_task_definition" "edrms" {
  family             = "${local.application_name}-task"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  network_mode       = "bridge"
  requires_compatibilities = [
    "EC2",
  ]
  cpu    = local.application_data.accounts[local.environment].container_cpu
  memory = local.application_data.accounts[local.environment].container_memory

  container_definitions = templatefile(
    "${path.module}/templates/task_definition_edrms.json.tpl",
    {
      app_name                      = local.application_name
      app_image                     = local.application_data.accounts[local.environment].app_image
      edrms_server_port             = local.application_data.accounts[local.environment].edrms_server_port
      aws_region                    = local.application_data.accounts[local.environment].aws_region
      container_version             = local.application_data.accounts[local.environment].container_version
      spring_profiles_active        = local.application_data.accounts[local.environment].spring_profiles_active
      spring_datasource_username    = local.application_data.accounts[local.environment].spring_datasource_username
      spring_datasource_password    = aws_secretsmanager_secret.spring_datasource_password.arn
      target_northgate_hub_dime_url = local.application_data.accounts[local.environment].target_northgate_hub_dime_url
      northgate_timeout             = local.application_data.accounts[local.environment].northgate_timeout
      spring_datasource_url         = aws_db_instance.tds_db.endpoint
      logging_level_root            = local.application_data.accounts[local.environment].logging_level_root
    }
  )

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-task", local.application_name, local.environment)) }
  )
}

# ECS Service

resource "aws_ecs_service" "edrms" {
  name            = local.application_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.edrms.arn
  desired_count   = local.application_data.accounts[local.environment].app_count
  launch_type     = "EC2"

  health_check_grace_period_seconds = 120
  #   lifecycle {
  #     ignore_changes = [
  #       task_definition
  #     ]
  #   }
  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.edrms_target_group.id
    container_name   = local.application_name
    container_port   = local.application_data.accounts[local.environment].edrms_server_port
  }

  depends_on = [
    aws_lb_listener.edrms,
    aws_iam_role_policy_attachment.ecs_task_execution_role,
    aws_autoscaling_group.cluster-scaling-group
  ]
}