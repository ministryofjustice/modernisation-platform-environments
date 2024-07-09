module "gdpr_ui_service" {
  source = "../helpers/delius_microservice"

  name                  = "gdpr-ui"
  certificate_arn       = local.certificate_arn
  alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  env_name              = var.env_name

  container_vars_default      = {}
  container_vars_env_specific = try(var.delius_microservice_configs.gdpr_ui.container_vars_env_specific, {})

  container_secrets_default      = {}
  container_secrets_env_specific = try(var.delius_microservice_configs.gdpr_ui.container_secrets_env_specific, {})

  desired_count = 0

  container_port_config = [
    {
      containerPort = var.delius_microservice_configs.gdpr_ui.container_port
      protocol      = "tcp"
    }
  ]
  ecs_cluster_arn            = module.ecs.ecs_cluster_arn
  db_ingress_security_groups = []
  cluster_security_group_id  = aws_security_group.cluster.id

  bastion_sg_id                      = module.bastion_linux.bastion_security_group
  tags                               = var.tags
  microservice_lb                    = aws_lb.delius_core_frontend
  microservice_lb_https_listener_arn = aws_lb_listener.listener_https.arn

  alb_listener_rule_paths = ["/gdpr/ui", "/gdpr/ui/*"]
  platform_vars           = var.platform_vars
  container_image         = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-gdpr-ui-ecr-repo:${var.delius_microservice_configs.gdpr_ui.image_tag}"
  account_config          = var.account_config
  health_check_path       = "/gdpr/ui/homepage"
  account_info            = var.account_info

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
