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
    },
    {
      name  = "USER_CONTEXT"
      value = "ou=Users,dc=moj,dc=com"
    },
    {
      name  = "EIS_USER_CONTEXT"
      value = "cn=EISUsers,ou=Users,dc=moj,dc=com"
    }
  ]
  container_secrets = [
    {
      name      = "JDBC_URL"
      valueFrom = aws_ssm_parameter.jdbc_url.arn
    },
    {
      name      = "JDBC_PASSWORD"
      valueFrom = aws_ssm_parameter.jdbc_password.arn
    },
    {
      name      = "LDAP_PRINCIPAL"
      valueFrom = aws_ssm_parameter.delius_core_ldap_principal.arn
    },
    { name      = "LDAP_CREDENTIAL"
      valueFrom = aws_secretsmanager_secret.delius_core_ldap_credential.arn
    }
  ]
  container_port_config = [
    {
      containerPort = 8080
      protocol      = "tcp"
  }]
  ecs_cluster_arn         = module.ecs.ecs_cluster_arn
  env_name                = var.env_name
  health_check_path       = "/NDelius-war/delius/JSP/healthcheck.jsp?ping"
  microservice_lb_arn     = aws_lb.delius_core_frontend.arn
  name                    = "weblogic"
  container_image         = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-weblogic-ecr-repo:${var.weblogic_config.image_tag}"
  platform_vars           = var.platform_vars
  tags                    = var.tags
  ingress_security_groups = []
}
