# module "pdf_creation" {
#   source = "../helpers/delius_microservice"

#   name                  = "pdf-creation"
#   certificate_arn       = local.certificate_arn
#   alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
#   env_name              = var.env_name

#   target_group_protocol_version = "HTTP1"

#   health_check = {
#     command = [
#       "CMD-SHELL",
#       "health=$(curl -sf http://localhost:8080/healthcheck || exit 1) && echo $health | jq -e '.status == \"OK\"'"
#     ]
#     interval    = 30
#     timeout     = 5
#     retries     = 2
#     startPeriod = 30
#   }

#   container_port_config = [
#     {
#       containerPort = var.delius_microservice_configs.pdf_creation.container_port
#       protocol      = "tcp"
#     }
#   ]

#   container_vars_default      = {}
#   container_vars_env_specific = try(var.delius_microservice_configs.pdf_creation.container_vars_env_specific, {})

#   container_secrets_default = {
#     #  JAVA_TOOL_OPTIONS = module.ssm_params_pdf_creation.arn_map["JAVA_TOOL_OPTIONS"]
#   }
#   container_secrets_env_specific = try(var.delius_microservice_configs.pdf_creation.container_secrets_env_specific, {})

#   desired_count = 1

#   ecs_cluster_arn            = module.ecs.ecs_cluster_arn
#   db_ingress_security_groups = []
#   cluster_security_group_id  = aws_security_group.cluster.id

#   bastion_sg_id = module.bastion_linux.bastion_security_group
#   tags          = var.tags

#   platform_vars   = var.platform_vars
#   container_image = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-new-tech-pdfgenerator:${var.delius_microservice_configs.pdf_creation.image_tag}"
#   account_config  = var.account_config
#   account_info    = var.account_info

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

# module "ssm_params_pdf_creation" {
#   source           = "../helpers/ssm_params"
#   application_name = "pdf_creation"
#   environment_name = var.env_name
#   params_secure    = ["JAVA_TOOL_OPTIONS"]
# }
