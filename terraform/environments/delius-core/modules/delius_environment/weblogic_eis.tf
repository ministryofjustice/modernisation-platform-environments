module "weblogic_eis" {
  source                = "../helpers/delius_microservice"
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
      name  = "AWS_XRAY_TRACING_NAME"
      value = "weblogic-eis"
    },
    {
      name  = "COOKIE_SECURE"
      value = "true"
    },
    {
      name  = "DELIUS_API_URL"
      value = "todo"
    },
    {
      name  = "DMS_HOST"
      value = "todo"
    },
    {
      name  = "DMS_OFFICE_URI_HOST"
      value = "todo"
    },
    {
      name  = "DMS_OFFICE_URI_PORT"
      value = "443"
    },
    {
      name  = "DMS_PORT"
      value = "443"
    },
    {
      name  = "DMS_PROTOCOL"
      value = "https"
    },
    {
      name  = "ELASTICSEARCH_URL"
      value = "/newTech"
    },
    {
      name  = "GDPR_URL"
      value = "/gdpr/ui/homepage"
    },
    {
      name  = "JDBC_CONNECTION_POOL_MAX_CAPACITY"
      value = "100"
    },
    {
      name  = "JDBC_CONNECTION_POOL_MIN_CAPACITY"
      value = "10"
    },
    {
      name  = "JDBC_DRIVER"
      value = "oracle.jdbc.OracleDriver"
    },
    {
      name  = "JDBC_INITIAL_CAPACITY"
      value = "10"
    },
    {
      name  = "JDBC_MAX_CAPACITY"
      value = "100"
    },
    {
      name  = "JDBC_MIN_CAPACITY"
      value = "50"
    },
    {
      name  = "JDBC_USERNAME"
      value = "delius_pool"
    },
    {
      name  = "LOG_LEVEL_NDELIUS"
      value = "INFO"
    },
    {
      name  = "MERGE_API_URL"
      value = "todo"
    },
    {
      name  = "MERGE_OAUTH_URL"
      value = "todo"
    },
    {
      name  = "MERGE_URL"
      value = "todo"
    },
    {
      name  = "USER_CONTEXT"
      value = "ou=Users,dc=moj,dc=com"
    },
    {
      name  = "EIS_USER_CONTEXT"
      value = "cn=EISUsers,ou=Users,dc=moj,dc=com"
    },
    {
      name  = "NDELIUS_CLIENT_ID"
      value = "NDelius"
    },
    {
      name  = "OTEL_RESOURCE_ATTRIBUTES"
      value = "service.name=weblogic-eis,service.namespace=${var.app_name}-${var.env_name}"
    },
    {
      name  = "PASSWORD_RESET_URL"
      value = "todo"
    },
    {
      name  = "TZ"
      value = "Europe/London"
    },
    {
      name  = "USER_MEM_ARGS"
      value = "-XX:MaxRAMPercentage=90.0"
    },
    {
      name  = "USERMANAGEMENT_URL"
      value = "/umt/"
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
    },
    {
      name      = "MERGE_SECRET"
      valueFrom = data.aws_ssm_parameter.delius_core_merge_api_client_secret.arn
    },
    {
      name      = "PDFCREATION_SECRET"
      valueFrom = data.aws_ssm_parameter.pdfcreation_secret.arn
    },
    {
      name      = "USERMANAGEMENT_SECRET"
      valueFrom = data.aws_ssm_parameter.usermanagement_secret.arn
    }
    #    {
    #      name      = "TOPIC_ARN"
    #      valueFrom = aws_sns_topic.delius_core_topic.arn
    #    }
  ]
  container_port_config = [
    {
      containerPort = 8080
      protocol      = "tcp"
    }
  ]

  name     = "weblogic-eis"
  env_name = var.env_name

  ecs_cluster_arn  = module.ecs.ecs_cluster_arn
  container_memory = var.delius_microservice_configs.weblogic_eis.container_memory
  container_cpu    = var.delius_microservice_configs.weblogic_eis.container_cpu

  health_check_path                 = "/NDelius-war/delius/JSP/healthcheck.jsp?ping"
  health_check_grace_period_seconds = 600
  health_check_interval             = 30

  db_ingress_security_groups = []

  cluster_security_group_id = aws_security_group.cluster.id

  microservice_lb                    = aws_lb.delius_core_frontend
  microservice_lb_https_listener_arn = aws_lb_listener.listener_https.arn
  alb_listener_rule_paths            = ["/eis"]

  container_image = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-weblogic-eis-ecr-repo:${var.delius_microservice_configs.weblogic_eis.image_tag}"

  bastion_sg_id = module.bastion_linux.bastion_security_group

  platform_vars = var.platform_vars
  tags          = var.tags

  providers = {
    aws          = aws
    aws.core-vpc = aws.core-vpc
  }
}


#######################
# Weblogic EIS Params #
#######################

resource "aws_ssm_parameter" "weblogic_eis_google_analytics_id" {
  name  = "/${var.env_name}/delius/monitoring/analytics/google_id"
  type  = "String"
  value = "DEFAULT"
  lifecycle {
    ignore_changes = [value]
  }
}

data "aws_ssm_parameter" "weblogic_eis_google_analytics_id" {
  name = aws_ssm_parameter.weblogic_eis_google_analytics_id.name
}



resource "aws_ssm_parameter" "usermanagement_secret" {
  name  = "/${var.env_name}/delius/umt/umt/delius_secret"
  type  = "SecureString"
  value = "DEFAULT"
  lifecycle {
    ignore_changes = [value]
  }
}

data "aws_ssm_parameter" "usermanagement_secret" {
  name = aws_ssm_parameter.usermanagement_secret.name
}
