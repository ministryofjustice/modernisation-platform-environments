module "weblogic" {
  source                = "../helpers/delius_microservice"
  account_config        = var.account_config
  account_info          = var.account_info
  alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  certificate_arn       = aws_acm_certificate.external.arn

  container_vars_default = {
    "JDBC_URL" : aws_ssm_parameter.jdbc_url.arn,
    "JDBC_PASSWORD" : aws_ssm_parameter.jdbc_password.arn,
    "LDAP_PRINCIPAL" : module.ldap.delius_core_ldap_principal_arn,
    "LDAP_CREDENTIAL" : module.ldap.delius_core_ldap_bind_password_arn
  }

  container_secrets_default      = {}
  container_secrets_env_specific = try(var.delius_microservice_configs.weblogic.container_secrets_env_specific, {})
  container_vars_env_specific    = try(var.delius_microservice_configs.weblogic.container_vars_env_specific, {})

  container_port_config = [
    {
      containerPort = var.delius_microservice_configs.weblogic.container_port
      protocol      = "tcp"
    }
  ]
  ecs_cluster_arn = module.ecs.ecs_cluster_arn
  env_name        = var.env_name

  health_check_path = "/NDelius-war/delius/JSP/healthcheck.jsp?ping"
  microservice_lb   = aws_lb.delius_core_frontend

  name                       = "weblogic"
  container_image            = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-weblogic-ecr-repo:${var.delius_microservice_configs.weblogic.image_tag}"
  platform_vars              = var.platform_vars
  tags                       = var.tags
  db_ingress_security_groups = []

  cluster_security_group_id = aws_security_group.cluster.id


  providers = {
    aws          = aws
    aws.core-vpc = aws.core-vpc
  }

  log_error_pattern      = "FATAL"
  sns_topic_arn          = aws_sns_topic.delius_core_alarms.arn
  frontend_lb_arn_suffix = aws_lb.delius_core_frontend.arn_suffix

  bastion_sg_id = module.bastion_linux.bastion_security_group
}
