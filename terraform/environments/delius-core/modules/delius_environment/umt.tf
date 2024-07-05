module "umt" {
  source                = "../helpers/delius_microservice"
  account_config        = var.account_config
  account_info          = var.account_info
  alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  certificate_arn       = aws_acm_certificate.external.arn

  container_vars_default      = {}
  container_vars_env_specific = try(var.delius_microservice_configs.umt.container_vars_env_specific, {})

  container_secrets_default      = {}
  container_secrets_env_specific = try(var.delius_microservice_configs.umt.container_secrets_env_specific, {})

  desired_count = 0

  container_port_config = [
    {
      containerPort = var.delius_microservice_configs.umt.container_port
      protocol      = "tcp"
    }
  ]

  name     = "umt"
  env_name = var.env_name

  ecs_cluster_arn  = module.ecs.ecs_cluster_arn
  container_memory = var.delius_microservice_configs.umt.container_memory
  container_cpu    = var.delius_microservice_configs.umt.container_cpu

  health_check_path                 = "/umt/actuator/health"
  health_check_grace_period_seconds = 600
  health_check_interval             = 30
  target_group_protocol_version     = "HTTP1"

  db_ingress_security_groups = []
  ecs_service_egress_security_group_ids = [
    {
      ip_protocol = "tcp"
      port        = 389
      cidr_ipv4   = var.account_config.shared_vpc_cidr
    },
    {
      ip_protocol = "tcp"
      port        = 1521
      cidr_ipv4   = var.environment_config.migration_environment_db_cidr[0]
    },
    {
      ip_protocol = "tcp"
      port        = 1521
      cidr_ipv4   = var.environment_config.migration_environment_db_cidr[1]
    },
    {
      ip_protocol = "tcp"
      port        = 1521
      cidr_ipv4   = var.environment_config.migration_environment_db_cidr[2]
    },
  ]

  cluster_security_group_id = aws_security_group.cluster.id

  bastion_sg_id = module.bastion_linux.bastion_security_group

  create_elasticache               = true
  elasticache_engine               = "redis"
  elasticache_engine_version       = var.delius_microservice_configs.umt.elasticache_version
  elasticache_node_type            = var.delius_microservice_configs.umt.elasticache_node_type
  elasticache_port                 = 6379
  elasticache_parameter_group_name = var.delius_microservice_configs.umt.elasticache_parameter_group_name
  elasticache_apply_immediately    = true
  elasticache_parameters = {
    "notify-keyspace-events" = "eA" # We need to turn on 'notify-keyspace-events' to support Spring Redis session expiration. See https://github.com/spring-projects/spring-session/issues/124
    "cluster-enabled"        = "yes"
  }


  microservice_lb                    = aws_lb.delius_core_frontend
  microservice_lb_https_listener_arn = aws_lb_listener.listener_https.arn
  alb_listener_rule_paths            = ["/umt"]

  container_image = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-user-management:${var.delius_microservice_configs.umt.image_tag}"

  platform_vars = var.platform_vars
  tags          = var.tags

  ignore_changes_service_task_definition = true

  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  log_error_pattern       = "ERROR"
  sns_topic_arn           = aws_sns_topic.delius_core_alarms.arn
  frontend_lb_arn_suffix  = aws_lb.delius_core_frontend.arn_suffix
  enable_platform_backups = var.enable_platform_backups
}

resource "aws_ssm_parameter" "elasticache_host" {
  name        = format("/%s-%s/umt/elasticache/host", var.account_info.application_name, var.env_name)
  description = "UMT ElastiCache Host"
  type        = "SecureString"
  value       = module.umt.elasticache_endpoint
}

resource "aws_ssm_parameter" "elasticache_port" {
  name        = format("/%s-%s/umt/elasticache/port", var.account_info.application_name, var.env_name)
  description = "UMT ElastiCache Port"
  type        = "SecureString"
  value       = module.umt.elasticache_port
}

resource "aws_vpc_security_group_egress_rule" "alb_to_umt" {
  security_group_id            = aws_security_group.delius_frontend_alb_security_group.id
  description                  = "load balancer to umt ecs service"
  from_port                    = "8080"
  to_port                      = "8080"
  ip_protocol                  = "tcp"
  referenced_security_group_id = module.umt.service_security_group_id
}
