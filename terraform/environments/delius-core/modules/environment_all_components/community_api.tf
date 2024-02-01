module "community_api" {
  source = "../components/delius_microservice"

  name                  = var.community_api.name
  certificate_arn       = aws_acm_certificate.external.arn
  alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  env_name              = var.env_name
  container_port_mappings = [
    {
      containerPort = var.community_api.container_port
      hostPort      = var.community_api.host_port
      protocol      = var.community_api.protocol
    }
  ]
  ecs_cluster_arn = module.ecs.ecs_cluster_arn
  container_secrets = [
    # {
    #   name      = "APPINSIGHTS_INSTRUMENTATIONKEY"
    #   valueFrom = "/${var.environment_name}/${var.project_name}/newtech/offenderapi/appinsights_key"
    # },
    # {
    #   name      = "SPRING_DATASOURCE_PASSWORD"
    #   valueFrom = "/${var.environment_name}/${var.project_name}/delius-database/db/delius_pool_password"
    # },
    # {
    #   name      = "SPRING_LDAP_PASSWORD"
    #   valueFrom = "/${var.environment_name}/${var.project_name}/apacheds/apacheds/ldap_admin_password"
    # },
    {
      name      = "DELIUS_USERNAME"
      valueFrom = aws_ssm_parameter.delius_core_frontend_env_var_dev_username.name
    #  value = "/${var.environment_name}/${var.project_name}/apacheds/apacheds/casenotes_user"
    },
    {
      name      = "DELIUS_PASSWORD"
      valueFrom = aws_ssm_parameter.delius_core_frontend_env_var_dev_password.name
    #  value = "/${var.environment_name}/${var.project_name}/apacheds/apacheds/casenotes_password"
    }
    # ,
    # {
    #   name      = "SENTRY_DSN"
    #   valueFrom = "/${var.environment_name}/${var.project_name}/probation-integration/community-api/sentry-dsn"
    # }
  ]
  ingress_security_groups = []
  tags                    = var.tags
  microservice_lb_arn     = aws_lb.delius_core_frontend.arn
  # microservice_lb_https_listener_arn = aws_lb_listener.listener_https.arn
  platform_vars     = var.platform_vars
  container_image   = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-community-api-ecr-repo:${var.community_api.image_tag}"
  account_config    = var.account_config
  health_check_path = "/health/ping"
  account_info      = var.account_info
  container_environment_vars = [
    {
      name  = "SPRING_PROFILES_ACTIVE"
      value = "oracle"
    },
    {
      name  = "SPRING_DATASOURCE_USERNAME"
      value = "delius_pool"
    },
    {
      name  = "SPRING_DATASOURCE_URL"
      value = aws_ssm_parameter.delius_core_community_api_env_var_jdbc_url.arn
      # value = data.terraform_remote_state.database.outputs.jdbc_failover_url
    },
    {
      name  = "DELIUS_LDAP_USERS_BASE"
      value = aws_ssm_parameter.delius_core_ldap_principal.arn
      # value = data.terraform_remote_state.ldap.outputs.ldap_base_users
    },
    {
      name  = "SPRING_LDAP_USERNAME"
      value = aws_secretsmanager_secret.delius_core_ldap_credential.arn
      # value = data.terraform_remote_state.ldap.outputs.ldap_bind_user
    },
    {
      name  = "SPRING_LDAP_URLS"
      value = "ldap://${module.ldap.nlb_dns_name}:${local.ldap_port}"
      # value = "${data.terraform_remote_state.ldap.outputs.ldap_protocol}://${data.terraform_remote_state.ldap.outputs.private_fqdn_ldap_elb}:${data.terraform_remote_state.ldap.outputs.ldap_port}"
    },
    # {
    #   name  = "ALFRESCO_BASEURL"
    #   value = "https://alfresco.${data.terraform_remote_state.vpc.outputs.public_zone_name}/alfresco/s/noms-spg"
    # },
    # {
    #   name  = "DELIUS_BASEURL"
    #   value = "http://${data.terraform_remote_state.interface.outputs.service_discovery_url}:7001/api"
    # },
    {
      name  = "SENTRY_ENVIRONMENT"
      value = var.env_name
    }
  ]
}
