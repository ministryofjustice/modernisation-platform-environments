module "container_definition" {
  source                   = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//container?ref=v5.0.0"
  name                     = var.name
  image                    = var.container_image
  memory                   = var.container_memory
  cpu                      = var.container_cpu
  essential                = true
  readonly_root_filesystem = false

  environment = local.calculated_container_vars_list

  health_check = var.container_health_check

  secrets       = local.calculated_container_secrets_list
  port_mappings = var.container_port_config
  mount_points  = var.mount_points
  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
      "awslogs-region"        = "eu-west-2"
      "awslogs-stream-prefix" = "${var.env_name}-${var.name}"
    }
  }
  system_controls = var.system_controls
}

module "ecs_policies" {
  source                        = "../ecs_policies"
  env_name                      = var.env_name
  service_name                  = var.name
  tags                          = var.tags
  extra_task_role_policies      = var.extra_task_role_policies
  extra_task_exec_role_policies = var.extra_task_exec_role_policies
}

module "ecs_service" {
  source                = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//service?ref=v5.0.0"
  container_definitions = nonsensitive(module.container_definition.json_encoded_list)
  cluster_arn           = var.ecs_cluster_arn
  name                  = "${var.env_name}-${var.name}"

  task_cpu    = var.container_cpu
  task_memory = var.container_memory

  pin_task_definition_revision = var.pin_task_definition_revision

  desired_count                      = var.desired_count
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent

  service_role_arn   = "arn:aws:iam::${var.account_info.id}:role/${module.ecs_policies.service_role.name}"
  task_role_arn      = "arn:aws:iam::${var.account_info.id}:role/${module.ecs_policies.task_role.name}"
  task_exec_role_arn = "arn:aws:iam::${var.account_info.id}:role/${module.ecs_policies.task_exec_role.name}"

  health_check_grace_period_seconds = var.alb_health_check.grace_period_seconds

  service_load_balancers = var.microservice_lb != null ? concat([{
    target_group_arn = aws_lb_target_group.frontend[0].arn
    container_name   = var.name
    container_port   = var.container_port_config[0].containerPort
    }],
  values(local.ecs_nlbs)) : values(local.ecs_nlbs)

  efs_volumes = var.efs_volumes

  security_groups = [aws_security_group.ecs_service.id, var.cluster_security_group_id]

  subnets = var.account_config.private_subnet_ids

  enable_execute_command = true

  tags = var.tags
}
