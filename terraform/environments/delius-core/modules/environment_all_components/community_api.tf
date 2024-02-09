module "community_api" {
  source = "../components/delius_microservice"

  name                  = "community-api"
  certificate_arn       = aws_acm_certificate.external.arn
  alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  env_name              = var.env_name
  container_port_config = [
    {
      containerPort = var.delius_microservice_configs.community_api.container_port
      protocol      = "tcp"
    }
  ]
  ecs_cluster_arn = module.ecs.ecs_cluster_arn
  container_secrets = [
    # {
    #   name      = "APPINSIGHTS_INSTRUMENTATIONKEY"
    #   valueFrom = "/${var.environment_name}/${var.project_name}/newtech/offenderapi/appinsights_key"
    # },
    {
      name      = "SPRING_DATASOURCE_PASSWORD"
      valueFrom = aws_ssm_parameter.jdbc_password.arn
      # valueFrom = "/${var.environment_name}/${var.project_name}/delius-database/db/delius_pool_password"
    }
    # ,
    # {
    #   name      = "SPRING_LDAP_PASSWORD"
    #   valueFrom = "/${var.environment_name}/${var.project_name}/apacheds/apacheds/ldap_admin_password"
    # },
    # {
    #   name      = "DELIUS_USERNAME"
    #   valueFrom = "/${var.environment_name}/${var.project_name}/apacheds/apacheds/casenotes_user"
    # },
    # {
    #   name      = "DELIUS_PASSWORD"
    #   valueFrom = "/${var.environment_name}/${var.project_name}/apacheds/apacheds/casenotes_password"
    # },
    # {
    #   name      = "SENTRY_DSN"
    #   valueFrom = "/${var.environment_name}/${var.project_name}/probation-integration/community-api/sentry-dsn"
    # }
  ]
  ingress_security_groups = []
  bastion_sg_id           = module.bastion_linux.bastion_security_group
  tags                    = var.tags
  # TODO - This LB is a placeholder marked no 13 on the architecture diagram: https://dsdmoj.atlassian.net/wiki/spaces/DAM/pages/3773105057/High-Level+Architecture
  # Two LBs (public and secure) are needed as show on the architecture diagram. There is an architectural discussion to be had if we could get away with just one LB instead
  microservice_lb_arn                = aws_lb.delius_core_frontend.arn
  microservice_lb_https_listener_arn = aws_lb_listener.listener_https.arn

  ecs_connectivity_nlb       = aws_lb.delius_microservices
  ecs_connectivity_listeners = aws_lb_listener.delius_microservices_listeners

  # Please check with the app team what the rule path should be here.
  alb_listener_rule_paths = ["/secure", "/secure/*"]
  platform_vars           = var.platform_vars
  container_image         = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-community-api-ecr-repo:${var.delius_microservice_configs.community_api.image_tag}"
  account_config          = var.account_config
  health_check_path       = "/health/ping"
  account_info            = var.account_info
  container_environment_vars = [
    {
      name = "SPRING_PROFILES_ACTIVE"
      # The value below is from the legacy
      value = "oracle"
    },
    {
      name = "SPRING_DATASOURCE_USERNAME"
      # The value below is from the legacy
      value = "delius_pool"
    },
    {
      name  = "SPRING_DATASOURCE_URL"
      value = aws_ssm_parameter.jdbc_url.arn
      # The value below is from the legacy
      # value = data.terraform_remote_state.database.outputs.jdbc_failover_url
    },
    {
      name  = "DELIUS_LDAP_USERS_BASE"
      value = module.ldap.delius_core_ldap_principal_arn
      # The value below is from the legacy
      # value = data.terraform_remote_state.ldap.outputs.ldap_base_users
    },
    {
      name  = "SPRING_LDAP_USERNAME"
      value = module.ldap.delius_core_ldap_principal_arn
      # The value below is from the legacy
      # value = data.terraform_remote_state.ldap.outputs.ldap_bind_user
    },
    {
      name  = "SPRING_LDAP_URLS"
      value = "ldap://${module.ldap.nlb_dns_name}:${var.ldap_config.port}"
      # The value below is from the legacy
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

  providers = {
    aws          = aws
    aws.core-vpc = aws.core-vpc
  }
}
