module "container_definition" {
  source                   = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=tags/0.61.1"
  container_name           = var.name
  container_image          = var.container_image
  container_memory         = var.container_memory
  container_cpu            = var.container_cpu
  essential                = true
  readonly_root_filesystem = false
  environment              = var.container_environment_vars
  secrets                  = var.container_secrets
  port_mappings            = var.container_port_config
  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
      "awslogs-region"        = "eu-west-2"
      "awslogs-stream-prefix" = "${var.env_name}-${var.name}"
    }
  }
}

module "ecs_policies" {
  source       = "../../ecs_policies"
  env_name     = var.env_name
  service_name = var.name
  tags         = var.tags
}

module "ecs_service" {
  source                    = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//service?ref=c195026bcf0a1958fa4d3cc2efefc56ed876507e"
  container_definition_json = module.container_definition.json_map_encoded_list
  ecs_cluster_arn           = var.ecs_cluster_arn
  name                      = var.name
  vpc_id                    = var.account_config.shared_vpc_id

  launch_type  = "FARGATE"
  network_mode = "awsvpc"

  task_cpu    = var.container_cpu
  task_memory = var.container_memory

  service_role_arn   = "arn:aws:iam::${var.account_info.id}:role/${module.ecs_policies.service_role.name}"
  task_role_arn      = "arn:aws:iam::${var.account_info.id}:role/${module.ecs_policies.task_role.name}"
  task_exec_role_arn = "arn:aws:iam::${var.account_info.id}:role/${module.ecs_policies.task_exec_role.name}"

  environment = var.env_name
  namespace   = "delius-core"

  health_check_grace_period_seconds = var.health_check_grace_period_seconds

  ecs_load_balancers = [
    {
      target_group_arn = aws_lb_target_group.this.arn
      container_name   = var.name
      container_port   = var.container_port_config[0].containerPort
    }
  ]

  security_group_ids = [aws_security_group.ecs_service.id]

  subnet_ids = var.account_config.private_subnet_ids

  exec_enabled = true

  ignore_changes_task_definition = true
  redeploy_on_apply              = false
  force_new_deployment           = false
}
