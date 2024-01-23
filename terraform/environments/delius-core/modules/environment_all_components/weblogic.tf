module "weblogic" {
  source                = "../components/delius_microservice"
  account_config        = var.account_config
  account_info          = var.account_info
  alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  certificate_arn       = aws_acm_certificate.external.arn
  container_environment_vars = [
    {
      name  = "LDAP_PORT"
      value = local.ldap_port
    },
    {
      name  = "LDAP_HOST"
      value = module.ldap.nlb_dns_name
    }
  ]
  container_secrets = [
    {
      name      = "JDBC_URL"
      valueFrom = aws_ssm_parameter.delius_core_frontend_env_var_jdbc_url.arn
    },
    {
      name      = "JDBC_PASSWORD"
      valueFrom = aws_ssm_parameter.delius_core_frontend_env_var_jdbc_password.arn
    },
    {
      name      = "TEST_MODE"
      valueFrom = aws_ssm_parameter.delius_core_frontend_env_var_test_mode.arn
    },
    {
      name      = "LDAP_PRINCIPAL"
      valueFrom = aws_ssm_parameter.delius_core_ldap_principal.arn
    },
    { name      = "LDAP_CREDENTIAL"
      valueFrom = aws_secretsmanager_secret.delius_core_ldap_credential.arn
    },
    {
      name      = "USER_CONTEXT"
      valueFrom = data.aws_ssm_parameter.delius_core_frontend_env_var_user_context.arn
    },
    {
      name      = "EIS_USER_CONTEXT"
      valueFrom = data.aws_ssm_parameter.delius_core_frontend_env_var_eis_user_context.arn
    }
  ]
  container_port_mappings = [
    {
      containerPort = var.weblogic_config.frontend_container_port
      hostPort      = var.weblogic_config.frontend_container_port
      protocol      = "tcp"
    },
  ]
  ecs_cluster_arn         = module.ecs.ecs_cluster_arn
  env_name                = var.env_name
  health_check_path       = "/NDelius-war/delius/JSP/healthcheck.jsp?ping"
  ingress_security_groups = []
  microservice_lb_arn     = aws_lb.delius_core_frontend.arn
  name                    = "weblogic"
  container_image         = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-weblogic-ecr-repo:${var.weblogic_config.frontend_image_tag}"
  platform_vars           = var.platform_vars
  tags                    = var.tags
}
