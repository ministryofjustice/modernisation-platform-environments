module "weblogic" {
  source                = "../components/delius_microservice"
  account_config        = var.account_config
  account_info          = var.account_info
  alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  certificate_arn       = aws_acm_certificate.external.arn
  container_environment_vars = [
    {
      name  = "LDAP_PORT"
      value = var.ldap_config.port
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
      valueFrom = module.ldap.delius_core_ldap_principal_arn
    },
    {
      name      = "LDAP_CREDENTIAL"
      valueFrom = module.ldap.delius_core_ldap_bind_password_arn
    }
  ]
  container_port_config = [
    {
      containerPort = var.delius_microservice_configs.weblogic.container_port
      protocol      = "tcp"
    }
  ]
  ecs_cluster_arn = module.ecs.ecs_cluster_arn
  env_name        = var.env_name

  health_check_path   = "/NDelius-war/delius/JSP/healthcheck.jsp?ping"
  microservice_lb_arn = aws_lb.delius_core_frontend.arn

  name                    = "weblogic"
  container_image         = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-weblogic-ecr-repo:${var.delius_microservice_configs.weblogic.image_tag}"
  platform_vars           = var.platform_vars
  tags                    = var.tags
  ingress_security_groups = []

  providers = {
    aws          = aws
    aws.core-vpc = aws.core-vpc
  }
  bastion_sg_id = module.bastion_linux.bastion_security_group
}
