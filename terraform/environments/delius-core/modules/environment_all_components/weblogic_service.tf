module "weblogic_container" {
  source                   = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=tags/0.59.0"
  container_name           = "${var.env_name}-weblogic"
  container_image          = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-weblogic-ecr-repo:${var.weblogic_config.frontend_image_tag}"
  container_memory         = 4096
  container_cpu            = 1024
  essential                = true
  readonly_root_filesystem = false
  secrets = [
    {
      name      = "JDBC_URL"
      valueFrom = aws_ssm_parameter.delius_core_frontend_env_var_jdbc_url.arn
    },
    {
      name      = "JDBC_PASSWORD"
      valueFrom = aws_ssm_parameter.delius_core_frontend_env_var_jdbc_password.arn
    },
    {
      name      = "TEST_MODE"
      valueFrom = aws_ssm_parameter.delius_core_frontend_env_var_test_mode.arn
    },
    {
      name      = "LDAP_PORT"
      valueFrom = data.aws_ssm_parameter.delius_core_frontend_env_var_ldap_port.arn
    },
    {
      name      = "LDAP_PRINCIPAL"
      valueFrom = data.aws_ssm_parameter.delius_core_frontend_env_var_ldap_principal.arn
    },
    { name      = "LDAP_CREDENTIAL"
      valueFrom = data.aws_secretsmanager_secret.ldap_credential.arn
    },
    {
      name      = "USER_CONTEXT"
      valueFrom = data.aws_ssm_parameter.delius_core_frontend_env_var_user_context.arn
    },
    {
      name      = "EIS_USER_CONTEXT"
      valueFrom = data.aws_ssm_parameter.delius_core_frontend_env_var_eis_user_context.arn
    }
  ]
  port_mappings = [
    {
      containerPort = var.weblogic_config.frontend_container_port
      hostPort      = var.weblogic_config.frontend_container_port
      protocol      = "tcp"
    },
  ]
  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = var.weblogic_config.frontend_fully_qualified_name
      "awslogs-region"        = "eu-west-2"
      "awslogs-stream-prefix" = var.weblogic_config.frontend_fully_qualified_name
    }
  }
}

module "weblogic_ecs_policies" {
  source       = "../ecs_policies"
  env_name     = var.env_name
  service_name = "weblogic"
  tags         = local.tags
}

module "deploy" {
  source                    = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//service?ref=5f488ac0de669f53e8283fff5bcedf5635034fe1"
  container_definition_json = module.weblogic_container.json_map_encoded_list
  ecs_cluster_arn           = module.ecs.ecs_cluster_arn
  name                      = "${var.env_name}-weblogic"
  vpc_id                    = var.network_config.shared_vpc_id

  launch_type  = "FARGATE"
  network_mode = "awsvpc"

  task_cpu    = "1024"
  task_memory = "4096"


  # terraform will not let you use module.weblogic_ecs_policies.service_role.arn as it is not created yet and can't evaluate the count in this module
  service_role_arn   = "arn:aws:iam::${var.account_info.id}:role/${module.weblogic_ecs_policies.service_role.name}"
  task_role_arn      = "arn:aws:iam::${var.account_info.id}:role/${module.weblogic_ecs_policies.task_role.name}"
  task_exec_role_arn = "arn:aws:iam::${var.account_info.id}:role/${module.weblogic_ecs_policies.task_exec_role.name}"

  environment = var.env_name

  health_check_grace_period_seconds = 0

  ecs_load_balancers = [
    {
      target_group_arn = aws_lb_target_group.delius_core_frontend_target_group.id
      container_name   = "${var.env_name}-weblogic"
      container_port   = 389
    }
  ]

  security_group_ids = [aws_security_group.weblogic.id]

  subnet_ids = var.network_config.private_subnet_ids

  exec_enabled = true

  ignore_changes_task_definition = false
  redeploy_on_apply              = false
  force_new_deployment           = false
}
