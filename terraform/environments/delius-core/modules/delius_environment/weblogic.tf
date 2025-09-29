module "weblogic" {
  source = "../helpers/delius_microservice"

  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  name            = "weblogic"
  container_image = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-weblogic:${var.delius_microservice_configs.weblogic.image_tag}"
  env_name        = var.env_name
  account_config  = var.account_config
  account_info    = var.account_info

  desired_count = 1

  pin_task_definition_revision           = try(var.delius_microservice_configs.weblogic.task_definition_revision, 0)
  ignore_changes_service_task_definition = false

  ecs_cluster_arn  = module.ecs.ecs_cluster_arn
  container_memory = var.delius_microservice_configs.weblogic.container_memory
  container_cpu    = var.delius_microservice_configs.weblogic.container_cpu

  container_vars_default = {
    for name in local.weblogic_ssm.vars : name => data.aws_ssm_parameter.weblogic_ssm[name].value
  }
  container_vars_env_specific = try(var.delius_microservice_configs.weblogic.container_vars_env_specific, {})

  container_secrets_default = merge({
    for name in local.weblogic_ssm.secrets : name => module.weblogic_ssm.arn_map[name]
    }, {
    "JDBC_PASSWORD" = "${module.oracle_db_shared.database_application_passwords_secret_arn}:delius_pool::"
    }
  )
  container_secrets_env_specific = try(var.delius_microservice_configs.weblogic.container_secrets_env_specific, {})

  container_port_config = [
    {
      containerPort = var.delius_microservice_configs.weblogic.container_port
      protocol      = "tcp"
    }
  ]

  cluster_security_group_id = aws_security_group.cluster.id

  alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  alb_health_check = {
    path                 = "/NDelius-war/delius/JSP/healthcheck.jsp?ping"
    healthy_threshold    = 5
    interval             = 30
    protocol             = "HTTP"
    unhealthy_threshold  = 5
    matcher              = "200-499"
    timeout              = 5
    grace_period_seconds = 300
  }

  certificate_arn               = aws_acm_certificate.external.arn
  target_group_protocol_version = "HTTP1"

  db_ingress_security_groups = []

  microservice_lb = aws_lb.delius_core_frontend

  bastion_sg_id = module.bastion_linux.bastion_security_group

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  ecs_service_ingress_security_group_ids = []
  ecs_service_egress_security_group_ids = [
    {
      ip_protocol = "tcp"
      port        = 389
      cidr_ipv4   = var.account_config.shared_vpc_cidr
    },
    {
      ip_protocol = "udp"
      port        = 389
      cidr_ipv4   = var.account_config.shared_vpc_cidr
    },
    {
      ip_protocol = "tcp"
      port        = 1521
      cidr_ipv4   = var.account_config.shared_vpc_cidr
    }
  ]

  log_error_pattern      = "FATAL"
  sns_topic_arn          = aws_sns_topic.delius_core_alarms.arn
  frontend_lb_arn_suffix = aws_lb.delius_core_frontend.arn_suffix

  platform_vars = var.platform_vars
  tags          = var.tags
}
