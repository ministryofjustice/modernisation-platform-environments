module "user_management" {
  source                = "../components/delius_microservice"
  account_config        = var.account_config
  account_info          = var.account_info
  alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  certificate_arn       = aws_acm_certificate.external.arn
  container_environment_vars = [
  ]
  container_secrets = [
  ]
  container_port_config = [
    {
      containerPort = 8080
      protocol      = "tcp"
    }
  ]

  name     = "user-management"
  env_name = var.env_name

  ecs_cluster_arn  = module.ecs.ecs_cluster_arn
  container_memory = var.weblogic_eis_config.container_memory
  container_cpu    = var.weblogic_eis_config.container_cpu

  health_check_path                 = "/umt"
  health_check_grace_period_seconds = 600
  health_check_interval             = 30

  ingress_security_groups = []

  microservice_lb_arn                = aws_lb.delius_core_frontend.arn
  microservice_lb_https_listener_arn = aws_lb_listener.listener_https.arn
  alb_listener_rule_priority         = 10
  alb_listener_rule_paths            = ["/umt"]

  container_image = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-weblogic-eis-ecr-repo:${var.user_management.image_tag}"

  platform_vars = var.platform_vars
  tags          = var.tags
}


#######################
# User management EIS Params #
#######################