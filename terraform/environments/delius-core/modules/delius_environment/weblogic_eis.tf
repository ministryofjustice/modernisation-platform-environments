module "weblogic_eis" {
  source                = "../helpers/delius_microservice"
  account_config        = var.account_config
  account_info          = var.account_info
  alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  certificate_arn       = aws_acm_certificate.external.arn

  container_vars_default = {
    "LDAP_PORT" : var.ldap_config.port,
    "LDAP_HOST" : module.ldap_ecs.nlb_dns_name,
    "AWS_XRAY_TRACING_NAME" : "weblogic-eis",
    "COOKIE_SECURE" : "true",
    "DELIUS_API_URL" : "todo",
    "DMS_HOST" : "todo",
    "DMS_OFFICE_URI_HOST" : "todo",
    "DMS_OFFICE_URI_PORT" : "443",
    "DMS_PORT" : "443",
    "DMS_PROTOCOL" : "https",
    "ELASTICSEARCH_URL" : "/newTech",
    "GDPR_URL" : "/gdpr/ui/homepage",
    "JDBC_CONNECTION_POOL_MAX_CAPACITY" : "100",
    "JDBC_CONNECTION_POOL_MIN_CAPACITY" : "10",
    "JDBC_DRIVER" : "oracle.jdbc.OracleDriver",
    "JDBC_INITIAL_CAPACITY" : "10",
    "JDBC_MAX_CAPACITY" : "100",
    "JDBC_MIN_CAPACITY" : "50",
    "JDBC_USERNAME" : "delius_pool",
    "LOG_LEVEL_NDELIUS" : "INFO",
    "MERGE_API_URL" : "todo",
    "MERGE_OAUTH_URL" : "todo",
    "MERGE_URL" : "todo",
    "USER_CONTEXT" : "ou=Users,dc=moj,dc=com",
    "EIS_USER_CONTEXT" : "cn=EISUsers,ou=Users,dc=moj,dc=com",
    "NDELIUS_CLIENT_ID" : "NDelius",
    "OTEL_RESOURCE_ATTRIBUTES" : "service.name=weblogic-eis,service.namespace=${var.app_name}-${var.env_name}",
    "PASSWORD_RESET_URL" : "todo",
    "TZ" : "Europe/London",
    "USER_MEM_ARGS" : "-XX:MaxRAMPercentage=90.0",
    "USERMANAGEMENT_URL" : "/umt/"
  }
  container_vars_env_specific = try(var.delius_microservice_configs.weblogic_eis.container_vars_env_specific, {})

  container_secrets_default = {
    "JDBC_URL" : aws_ssm_parameter.jdbc_url.arn,
    "JDBC_PASSWORD" : aws_ssm_parameter.jdbc_password.arn,
    "LDAP_PRINCIPAL" : aws_ssm_parameter.ldap_principal.arn,
    "LDAP_CREDENTIAL" : aws_ssm_parameter.ldap_bind_password.arn,
    "MERGE_SECRET" : data.aws_ssm_parameter.delius_core_merge_api_client_secret.arn,
    "PDFCREATION_SECRET" : data.aws_ssm_parameter.pdfcreation_secret.arn,
    "USERMANAGEMENT_SECRET" : data.aws_ssm_parameter.usermanagement_secret.arn
  }

  container_secrets_env_specific = try(var.delius_microservice_configs.weblogic_eis.container_secrets_env_specific, {})

  desired_count = 0

  container_port_config = [
    {
      containerPort = 8080
      protocol      = "tcp"
    }
  ]

  name     = "weblogic-eis"
  env_name = var.env_name

  pin_task_definition_revision = try(var.delius_microservice_configs.weblogic_eis.task_definition_revision, 0)

  ecs_cluster_arn  = module.ecs.ecs_cluster_arn
  container_memory = var.delius_microservice_configs.weblogic_eis.container_memory
  container_cpu    = var.delius_microservice_configs.weblogic_eis.container_cpu

  alb_health_check = {
    path                 = "/NDelius-war/delius/JSP/healthcheck.jsp?ping"
    healthy_threshold    = 5
    interval             = 30
    protocol             = "HTTP"
    unhealthy_threshold  = 5
    matcher              = "200-499"
    timeout              = 10
    grace_period_seconds = 300
  }

  db_ingress_security_groups = []

  cluster_security_group_id = aws_security_group.cluster.id

  microservice_lb                    = aws_lb.delius_core_frontend
  microservice_lb_https_listener_arn = aws_lb_listener.listener_https.arn
  alb_listener_rule_paths            = ["/eis"]
  alb_listener_rule_priority         = 40

  container_image = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-weblogic:${var.delius_microservice_configs.weblogic_eis.image_tag}"

  bastion_sg_id = module.bastion_linux.bastion_security_group

  platform_vars = var.platform_vars
  tags          = var.tags

  ignore_changes_service_task_definition = false

  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  log_error_pattern       = ""
  sns_topic_arn           = aws_sns_topic.delius_core_alarms.arn
  frontend_lb_arn_suffix  = aws_lb.delius_core_frontend.arn_suffix
  enable_platform_backups = var.enable_platform_backups
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
