module "container_definition" {
  source                   = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=tags/0.61.1"
  container_name           = "${var.name}-${var.env_name}"
  container_image          = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-weblogic-ecr-repo:${var.weblogic_config.frontend_image_tag}"
  container_memory         = 4096
  container_cpu            = 1024
  essential                = true
  readonly_root_filesystem = false
  environment              = var.container_environment_vars
  secrets                  = var.container_secrets
  port_mappings            = var.container_port_mappings
  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = aws_cloudwatch_log_group.delius_core_frontend_log_group.name
      "awslogs-region"        = "eu-west-2"
      "awslogs-stream-prefix" = var.weblogic_config.frontend_fully_qualified_name
    }
  }
}

module "ecs_policies" {
  source       = "../../ecs_policies"
  env_name     = var.env_name
  service_name = var.name
  tags         = var.tags
}

module "weblogic_service" {
  source                    = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//service?ref=c195026bcf0a1958fa4d3cc2efefc56ed876507e"
  container_definition_json = module.weblogic_container.json_map_encoded_list
  ecs_cluster_arn           = module.ecs.ecs_cluster_arn
  name                      = "weblogic"
  vpc_id                    = var.account_config.shared_vpc_id

  launch_type  = "FARGATE"
  network_mode = "awsvpc"

  task_cpu    = "1024"
  task_memory = "4096"

  # terraform will not let you use module.weblogic_ecs_policies.service_role.arn as it is not created yet and can't evaluate the count in this module
  service_role_arn   = module.ecs_policies.service_role.arn
  task_role_arn      = module.ecs_policies.task_role.arn
  task_exec_role_arn = module.ecs_policies.task_exec_role.arn

  environment = var.env_name
  namespace   = "delius-core"

  health_check_grace_period_seconds = var.health_check_grace_period_seconds

  ecs_load_balancers = [
    {
      target_group_arn = aws_lb_target_group.delius_core_frontend_target_group.id
      container_name   = "${var.env_name}-weblogic"
      container_port   = var.task_def_container_port
    }
  ]

  security_group_ids = [aws_security_group.ecs_service.id]

  subnet_ids = var.account_config.private_subnet_ids

  exec_enabled = true

  ignore_changes_task_definition = true
  redeploy_on_apply              = false
  force_new_deployment           = false
}
