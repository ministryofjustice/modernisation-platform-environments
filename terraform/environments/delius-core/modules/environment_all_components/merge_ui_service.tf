module "merge_ui_service" {
  source = "../components/delius_microservice"

  name                  = "merge-ui"
  certificate_arn       = local.certificate_arn
  alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  env_name              = var.env_name
  container_port_config = [
    {
      containerPort = 80
      protocol      = "tcp"
    }
  ]
  ecs_cluster_arn                    = module.ecs.ecs_cluster_arn
  container_secrets                  = []
  ingress_security_groups            = []
  tags                               = var.tags
  microservice_lb_arn                = aws_lb.delius_core_frontend.arn
  microservice_lb_https_listener_arn = aws_lb_listener.listener_https.arn
  alb_listener_rule_priority         = 8
  alb_listener_rule_paths            = ["/merge/ui", "/merge/ui/*"]
  platform_vars                      = var.platform_vars
  container_image                    = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-merge-ui-ecr-repo:${var.merge_config.ui_image_tag}"
  account_config                     = var.account_config
  health_check_path                  = "/merge/ui/"
  account_info                       = var.account_info
  container_environment_vars         = []
}
