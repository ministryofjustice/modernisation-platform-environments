################################################################################
# Service
################################################################################
data "aws_secretsmanager_secret_version" "postgres_secret" {
  count     = var.get_postgres_secret ? 1 : 0
  secret_id = var.ecs_service_postgres_secret_arn
}

#For each ecs service create a service module
module "ecs_service" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  for_each = var.ecs_services
  source   = "terraform-aws-modules/ecs/aws//modules/service"
  version  = "5.11.2"

  # Service
  name        = each.value.name
  cluster_arn = module.ecs_cluster.arn

  # Task Definition
  requires_compatibilities           = ["EC2"]
  launch_type                        = "EC2"
  desired_count                      = each.value.desired_count
  deployment_maximum_percent         = each.value.deployment_maximum_percent
  deployment_minimum_healthy_percent = each.value.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = each.value.health_check_grace_period_seconds
  autoscaling_max_capacity           = try(each.value.autoscaling_max_capacity, 4)
  autoscaling_min_capacity           = try(each.value.autoscaling_min_capacity, 2)
  autoscaling_policies               = local.autoscaling_policies
  force_new_deployment               = false
  #ec2 capacity_provider_strategy  spread (attribute:ecs.availability-zone), spread (instanceId) todo
  # Container definition(s)
  cpu    = try(each.value.task_cpu, each.value.container_cpu)
  memory = try(each.value.task_memory, each.value.container_memory)
  volume = concat(each.value.volumes, local.default_volumes)
  #container_definitions = local.consolidated_container_definitions
  container_definitions = merge(each.value.additional_container_definitions, {
    (each.value.name) = {
      image = each.value.image
      port_mappings = concat(each.value.additional_port_mappings, [{
        name          = each.value.name
        containerPort = each.value.container_port
        hostPort      = each.value.container_port
        protocol      = "tcp"
      }])

      cpu                      = try(each.value.container_cpu, each.value.task_cpu - 20)
      memory                   = try(each.value.container_memory, each.value.task_memory - 40)
      essential                = try(each.value.essential, true)
      mount_points             = concat(each.value.additional_mount_points, local.default_mountpoints)
      readonly_root_filesystem = each.value.readonly_root_filesystem

      enable_cloudwatch_logging              = true
      create_cloudwatch_log_group            = true
      cloudwatch_log_group_name              = "/ecs/${each.value.name}"
      cloudwatch_log_group_retention_in_days = each.value.cloudwatch_log_group_retention_in_days

      log_configuration = {
        logDriver = "awslogs"
      }

      environment = concat(each.value.additional_environment_variables, local.default_environment_variables,
        [
          {
            "name" : "SPRING_PROFILES_ACTIVE",
            "value" : var.environment
          },
          {
            "name" : "DD_SERVICE",
            "value" : each.value.name
          },
          {
            "name" : "DD_ENV",
            "value" : var.environment
        }]
      )
      secrets = each.value.enable_postgres_secret ? concat(each.value.secrets, [
        {
          name      = "postgres_password"
          valueFrom = try(data.aws_secretsmanager_secret_version.postgres_secret[0].secret_string, null)
        }
      ]) : each.value.secrets
      docker_labels = merge(try(each.value.dockerLabels, null), {
        "com.datadoghq.tags.service" : each.value.name,
        "com.datadoghq.tags.env" : var.environment,
      })
      health_check = each.value.enable_healthcheck ? {
        command = each.value.health_check.command
      } : {}
      command     = each.value.command
      entry_point = each.value.entry_point
    }
  })
  ignore_task_definition_changes = true
  load_balancer = each.value.internal_only ? {
    service = {
      target_group_arn = each.value.load_balancer_target_group_arn != null ? each.value.load_balancer_target_group_arn : lookup(var.list_of_target_group_arns, "${each.key}-target-group-1", null)
      container_name   = each.value.name
      container_port   = each.value.container_port
    }
    } : {
    cloudfront = {
      target_group_arn = each.value.load_balancer_target_group_arn != null ? each.value.load_balancer_target_group_arn : lookup(var.list_of_target_group_arns, "${each.key}-target-group-1", null)
      container_name   = each.value.name
      container_port   = each.value.container_port
    }
  }

  deployment_controller = {
    type = each.value.deployment_controller
  }

  subnet_ids                = var.ecs_subnet_ids
  create_security_group     = false
  security_group_ids        = each.value.internal_only ? [aws_security_group.common_ecs_service_internal.id] : [aws_security_group.common_ecs_service_external.id]
  tasks_iam_role_arn        = aws_iam_role.ecs_task_role.arn
  create_tasks_iam_role     = false
  create_task_exec_iam_role = false
  task_exec_iam_role_arn    = aws_iam_role.ecs_task_execution_role.arn

  tags = merge(each.value.tags, local.all_tags)
}

