module "weblogic" {
  source                = "../helpers/delius_microservice"
  account_config        = var.account_config
  account_info          = var.account_info
  alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  certificate_arn       = aws_acm_certificate.external.arn

  # container_vars_default = {
  #   "JDBC_URL" : aws_ssm_parameter.jdbc_url.arn,
  #   "JDBC_PASSWORD" : aws_ssm_parameter.jdbc_password.arn,
  #   "LDAP_PRINCIPAL" : aws_ssm_parameter.ldap_principal.arn,
  #   "LDAP_CREDENTIAL" : aws_ssm_parameter.ldap_bind_password.arn
  # }

  desired_count = 0

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

  ignore_changes_service_task_definition = true

  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  log_error_pattern      = "FATAL"
  sns_topic_arn          = aws_sns_topic.delius_core_alarms.arn
  frontend_lb_arn_suffix = aws_lb.delius_core_frontend.arn_suffix

  bastion_sg_id = module.bastion_linux.bastion_security_group

  container_vars_default = {
    "PSR_SERVICE_URL" : aws_ssm_parameter.weblogic_psr_service_url.arn,
    "TZ" : aws_ssm_parameter.weblogic_tz.arn,
    "PDFCREATION_URL" : aws_ssm_parameter.weblogic_pdfcreation_url.arn,
    "OFFENDER_SEARCH_API_URL" : aws_ssm_parameter.weblogic_offender_search_api_url.arn,
    "DMS_OFFICE_URI_PORT" : aws_ssm_parameter.weblogic_dms_office_uri_port.arn,
    "MERGE_URL" : aws_ssm_parameter.weblogic_merge_url.arn,
    "OAUTH_TOKEN_VERIFICATION_URL" : aws_ssm_parameter.weblogic_oauth_token_verification_url.arn,
    "API_CLIENT_ID" : aws_ssm_parameter.weblogic_api_client_id.arn,
    "DMS_PROTOCOL" : aws_ssm_parameter.weblogic_dms_protocol.arn,
    "JDBC_CONNECTION_POOL_MIN_CAPACITY" : aws_ssm_parameter.weblogic_jdbc_connection_pool_min_capacity.arn,
    "PDFCREATION_TEMPLATES" : aws_ssm_parameter.weblogic_pdfcreation_templates.arn,
    "DMS_HOST" : aws_ssm_parameter.weblogic_dms_host.arn,
    "COOKIE_SECURE" : aws_ssm_parameter.weblogic_cookie_secure.arn,
    "USERMANAGEMENT_URL" : aws_ssm_parameter.weblogic_usermanagement_url.arn,
    "DELIUS_API_URL" : aws_ssm_parameter.weblogic_delius_api_url.arn,
    "OAUTH_DEFAULT_SCOPE" : aws_ssm_parameter.weblogic_oauth_default_scope.arn,
    "GDPR_URL" : aws_ssm_parameter.weblogic_gdpr_url.arn,
    "AWS_REGION" : aws_ssm_parameter.weblogic_aws_region.arn,
    "OAUTH_LOGIN_ENABLED" : aws_ssm_parameter.weblogic_oauth_login_enabled.arn,
    "DMS_OFFICE_URI_HOST" : aws_ssm_parameter.weblogic_dms_office_uri_host.arn,
    "JDBC_CONNECTION_POOL_MAX_CAPACITY" : aws_ssm_parameter.weblogic_jdbc_connection_pool_max_capacity.arn,
    "DMS_PORT" : aws_ssm_parameter.weblogic_dms_port.arn,
    "OAUTH_LOGIN_NAME" : aws_ssm_parameter.weblogic_oauth_login_name.arn,
    "JDBC_USERNAME" : aws_ssm_parameter.weblogic_jdbc_username.arn,
    "USER_MEM_ARGS" : aws_ssm_parameter.weblogic_user_mem_args.arn,
    "NDELIUS_CLIENT_ID" : aws_ssm_parameter.weblogic_ndelius_client_id.arn,
    "JDBC_URL" : aws_ssm_parameter.weblogic_jdbc_url.arn,
    "USER_CONTEXT" : aws_ssm_parameter.weblogic_user_context.arn,
    "OAUTH_URL" : aws_ssm_parameter.weblogic_oauth_url.arn,
    "PASSWORD_RESET_URL" : aws_ssm_parameter.weblogic_password_reset_url.arn,
    "LOG_LEVEL_NDELIUS" : aws_ssm_parameter.weblogic_log_level_ndelius.arn,
    "LDAP_HOST" : aws_ssm_parameter.weblogic_ldap_host.arn,
    "MERGE_API_URL" : aws_ssm_parameter.weblogic_merge_api_url.arn,
    "ELASTICSEARCH_URL" : aws_ssm_parameter.weblogic_elasticsearch_url.arn,
    "OAUTH_CLIENT_ID" : aws_ssm_parameter.weblogic_oauth_client_id.arn,
    "LDAP_PRINCIPAL" : aws_ssm_parameter.weblogic_ldap_principal.arn,
    "OAUTH_CALLBACK_URL" : aws_ssm_parameter.weblogic_oauth_callback_url.arn,
    "EIS_USER_CONTEXT" : aws_ssm_parameter.weblogic_eis_user_context.arn,
    "MERGE_OAUTH_URL" : aws_ssm_parameter.weblogic_merge_oauth_url.arn
  }

  container_secrets_default = {
    "ADMIN_PASSWORD" : aws_ssm_parameter.weblogic_admin_password.arn,
    "ANALYTICS_TAG" : aws_ssm_parameter.weblogic_analytics_tag.arn,
    "API_CLIENT_SECRET" : aws_ssm_parameter.weblogic_api_client_secret.arn,
    "APPLICATIONINSIGHTS_CONNECTION_STRING" : aws_ssm_parameter.weblogic_applicationinsights_connection_string.arn,
    "AWS_ACCESS_KEY_ID" : aws_ssm_parameter.weblogic_aws_access_key_id.arn,
    "AWS_SECRET_ACCESS_KEY" : aws_ssm_parameter.weblogic_aws_secret_access_key.arn,
    "JDBC_PASSWORD" : aws_ssm_parameter.weblogic_jdbc_password.arn,
    "LDAP_CREDENTIAL" : aws_ssm_parameter.weblogic_ldap_credential.arn,
    "MERGE_SECRET" : aws_ssm_parameter.weblogic_merge_secret.arn,
    "OAUTH_CLIENT_SECRET" : aws_ssm_parameter.weblogic_oauth_client_secret.arn,
    "PDFCREATION_SECRET" : aws_ssm_parameter.weblogic_pdfcreation_secret.arn,
    "TOPIC_ARN" : aws_ssm_parameter.weblogic_topic_arn.arn,
    "USERMANAGEMENT_SECRET" : aws_ssm_parameter.weblogic_usermanagement_secret.arn
  }


}
