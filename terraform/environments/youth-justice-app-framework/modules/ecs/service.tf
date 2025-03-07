################################################################################
# Service
################################################################################
data "aws_secretsmanager_secret_version" "postgres_secret" {
  count     = var.get_postgres_secret ? 1 : 0
  secret_id = var.ecs_service_postgres_secret_arn
}

data "aws_lb_target_group" "target_group" {
  for_each = var.ecs_services
  name     = "${each.value.name}-target-group-1"
}

data "aws_lb_target_group" "external_target_group" {
  #for each ecs service if internal_only is false create a target group
  for_each = { for k, v in var.ecs_services : k => v if v.internal_only == false }
  name     = "${each.value.name}-target-group-2"
}
/* commented out as not allowed and may not need it anyway
resource "aws_service_discovery_service" "service_discovery" {
  for_each     = var.ecs_services
  name         = each.value.name
  namespace_id = aws_service_discovery_private_dns_namespace.namespace.id

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.namespace.id
    dns_records {
      type = "A"
      ttl  = 60
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
*/
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
  autoscaling_max_capacity           = try(each.value.autoscaling_max_capacity, 4)
  autoscaling_policies               = local.autoscaling_policies
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
      essential                = true
      mount_points             = concat(each.value.additional_mount_points, local.default_mountpoints)
      readonly_root_filesystem = each.value.readonly_root_filesystem

      enable_cloudwatch_logging              = true
      create_cloudwatch_log_group            = true
      cloudwatch_log_group_name              = "/aws/ecs/${each.value.name}"
      cloudwatch_log_group_retention_in_days = each.value.cloudwatch_log_group_retention_in_days

      log_configuration = {
        logDriver = "awslogs"
      }

      environment = concat(each.value.additional_environment_variables, local.default_environment_variables,
        [
          {
            "name" : "SPRING_PROFILES_ACTIVE",
            "value" : "moj-${var.environment}"
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
      health_check = {
        command = each.value.health_check.command
      }
      command    = each.value.command
      entryPoint = each.value.entryPoint
    }
  })
  ignore_task_definition_changes = true
  load_balancer = each.value.internal_only ? {
    service = {
      #      elb_name = var.internal_alb_name
      target_group_arn = each.value.load_balancer_target_group_arn != null ? each.value.load_balancer_target_group_arn : data.aws_lb_target_group.target_group[each.key].arn
      container_name   = each.value.name
      container_port   = each.value.container_port
    }
    } : {
    service = {
      #      elb_name = var.internal_alb_name
      target_group_arn = each.value.load_balancer_target_group_arn != null ? each.value.load_balancer_target_group_arn : data.aws_lb_target_group.target_group[each.key].arn
      container_name   = each.value.name
      container_port   = each.value.container_port
    },
    cloudfront = {
      #      elb_name = var.external_alb_name
      target_group_arn = each.value.load_balancer_target_group_arn != null ? each.value.load_balancer_target_group_arn : data.aws_lb_target_group.external_target_group[each.key].arn
      container_name   = each.value.name
      container_port   = each.value.container_port
    }
  }

  #service_registries = {
  #  container_name = each.value.name
  #  registry_arn   = aws_service_discovery_service.service_discovery[each.key].arn
  #}

  deployment_controller = {
    type = each.value.deployment_controller
  }

  subnet_ids                 = var.ecs_subnet_ids
  create_security_group      = false
  security_group_ids         = each.value.internal_only ? [aws_security_group.common_ecs_service_internal.id] : [aws_security_group.common_ecs_service_external.id]
  tasks_iam_role_name        = each.value.ecs_task_iam_role_name
  create_tasks_iam_role      = false
  tasks_iam_role_description = "IAM role for ECS tasks"
  create_task_exec_iam_role  = false
  task_exec_iam_role_arn     = aws_iam_role.ecs_task_execution_role.arn

  tags = merge(each.value.tags, local.all_tags)
}

