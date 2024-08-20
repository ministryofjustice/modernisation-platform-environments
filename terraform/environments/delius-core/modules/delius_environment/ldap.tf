module "ldap" {

  source = "../components/ldap"

  providers = {
    aws                       = aws
    aws.bucket-replication    = aws.bucket-replication
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  env_name           = var.env_name
  account_config     = var.account_config
  account_info       = var.account_info
  environment_config = var.environment_config
  ldap_config        = var.ldap_config

  bastion_sg_id = module.bastion_linux.bastion_security_group

  sns_topic_arn   = aws_sns_topic.delius_core_alarms.arn
  ecs_cluster_arn = module.ecs.ecs_cluster_arn

  platform_vars           = var.platform_vars
  tags                    = local.tags
  enable_platform_backups = var.enable_platform_backups
}




module "ldap_microservice" {
  source = "../helpers/delius_microservice"

  name                  = "ldap"
  certificate_arn       = local.certificate_arn
  alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  env_name              = var.env_name

  container_vars_default      = {}
  container_vars_env_specific = try(var.delius_microservice_configs.ldap.container_vars_env_specific, {})

  container_secrets_default      = {}
  container_secrets_env_specific = try(var.delius_microservice_configs.ldap.container_secrets_env_specific, {})

  desired_count = 0

  container_port_config = [
    {
      containerPort = var.delius_microservice_configs.ldap.container_port
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

  platform_vars           = var.platform_vars
  container_image         = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-ldap:${var.delius_microservice_configs.ldap.image_tag}" # CHANGE ME
  account_config          = var.account_config
  health_check = {
    command     = ["CMD-SHELL", "ldapsearch -x -H ldap://localhost:389 -b '' -s base '(objectclass=*)' namingContexts"]
    interval    = 30
    retries     = 3
    startPeriod = 60
    timeout     = 5
  }
  account_info            = var.account_info

  ignore_changes_service_task_definition = false

  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  log_error_pattern       = "ERROR"
  sns_topic_arn           = aws_sns_topic.delius_core_alarms.arn
  frontend_lb_arn_suffix  = aws_lb.delius_core_frontend.arn_suffix
  enable_platform_backups = var.enable_platform_backups
}
