module "gdpr_ui_service" {
  source = "../components/delius_microservice"

  name = "gdpr-ui"
  certificate_arn = local.certificate_arn
  alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  env_name = var.env_name
  container_port_mappings = [
    {
      containerPort = 80
      hostPort      = 80 # check this
      protocol      = "tcp"
    }
  ]
  ecs_cluster_arn = module.ecs.ecs_cluster_arn
  container_secrets = []
  ingress_security_groups = []
  tags = var.tags
  microservice_lb_arn = aws_lb.delius_core_frontend.arn
  platform_vars = var.platform_vars
  container_image = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-gdpr-ui-ecr-repo:${var.gdpr_config.ui_image_tag}"
  account_config = var.account_config
  health_check_path = "/gdpr/ui/homepage"
  account_info = var.account_info
  container_environment_vars = []
}