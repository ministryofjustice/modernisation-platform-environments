# module "newtech" {
#   source = "../helpers/delius_microservice"

#   name                  = "newtech"
#   certificate_arn       = local.certificate_arn
#   alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
#   env_name              = var.env_name

#   container_vars_default      = {}
#   container_vars_env_specific = try(var.delius_microservice_configs.newtech.container_vars_env_specific, {})

#   container_secrets_default      = {}
#   container_secrets_env_specific = try(var.delius_microservice_configs.newtech.container_secrets_env_specific, {})

#   desired_count = 0

#   container_port_config = [
#     {
#       containerPort = var.delius_microservice_configs.newtech.container_port
#       protocol      = "tcp"
#     }
#   ]

#   ecs_cluster_arn            = module.ecs.ecs_cluster_arn
#   db_ingress_security_groups = []
#   cluster_security_group_id  = aws_security_group.cluster.id

#   bastion_sg_id                      = module.bastion_linux.bastion_security_group
#   tags                               = var.tags
#   microservice_lb                    = aws_lb.delius_core_frontend
#   microservice_lb_https_listener_arn = aws_lb_listener.listener_https.arn

#   alb_listener_rule_paths = ["/newtech", "/newtech/*"]
#   platform_vars           = var.platform_vars
#   container_image         = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-new-tech-web:${var.delius_microservice_configs.newtech.image_tag}"
#   account_config          = var.account_config
#   health_check_path       = "/newtech"
#   account_info            = var.account_info

#   ignore_changes_service_task_definition = false

#   providers = {
#     aws.core-vpc              = aws.core-vpc
#     aws.core-network-services = aws.core-network-services
#   }

#   log_error_pattern       = "ERROR"
#   sns_topic_arn           = aws_sns_topic.delius_core_alarms.arn
#   frontend_lb_arn_suffix  = aws_lb.delius_core_frontend.arn_suffix
#   enable_platform_backups = var.enable_platform_backups
# }

resource "aws_ssm_parameter" "pdfcreation_secret" {
  name  = "/${var.env_name}/delius/newtech/web/params_secret_key"
  type  = "SecureString"
  value = "DEFAULT"
  lifecycle {
    ignore_changes = [value]
  }
}

data "aws_ssm_parameter" "pdfcreation_secret" {
  name = aws_ssm_parameter.pdfcreation_secret.name
}
