module "merge_api_service" {
  source = "../components/delius_microservice"

  name                  = "merge-api"
  certificate_arn       = local.certificate_arn
  alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  env_name              = var.env_name
  container_port_config = [
    {
      containerPort = 8080
      protocol      = "tcp"
    }
  ]
  ecs_cluster_arn = module.ecs.ecs_cluster_arn
  container_secrets = [
    {
      name      = "SPRING_DATASOURCE_PASSWORD"
      valueFrom = aws_ssm_parameter.delius_core_merge_db_admin_password.arn
    },
    {
      name      = "SPRING_SECOND-DATASOURCE_PASSWORD"
      valueFrom = aws_ssm_parameter.delius_core_merge_db_pool_password.arn
    },
    {
      name      = "SPRING_SECURITY_OAUTH2_RESOURCESERVER_OPAQUE-TOKEN_CLIENT-SECRET"
      valueFrom = aws_ssm_parameter.delius_core_merge_api_client_secret.arn
    }
  ]
  ingress_security_groups            = []
  tags                               = var.tags
  microservice_lb_arn                = aws_lb.delius_core_frontend.arn
  microservice_lb_https_listener_arn = aws_lb_listener.listener_https.arn
  alb_listener_rule_paths            = ["/merge/api", "/merge/api/*"]
  platform_vars                      = var.platform_vars
  container_image                    = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-merge-api-ecr-repo:${var.merge_config.api_image_tag}"
  account_config                     = var.account_config
  health_check_path                  = "/merge/api/actuator/health"
  account_info                       = var.account_info
  container_environment_vars = [
    {
      name  = "SERVER_SERVLET_CONTEXT_PATH"
      value = "/merge/api/"
    },
    #    {
    #      name  = "SPRING_DATASOURCE_JDBC_URL"
    #      value = "jdbc:postgresql://${aws_db_instance.primary.endpoint}/${aws_db_instance.primary.name}"
    #    },
    #    {
    #      name  = "SPRING_DATASOURCE_USERNAME"
    #      value = aws_db_instance.primary.username
    #    },
    {
      name  = "SPRING_DATASOURCE_DRIVER_CLASS_NAME"
      value = "org.postgresql.Driver"
    },
    #    {
    #      name  = "SPRING_SECOND_DATASOURCE_JDBC_URL"
    #      value = data.terraform_remote_state.database.outputs.jdbc_failover_url
    #    },
    {
      name  = "SPRING_SECOND_DATASOURCE_USERNAME"
      value = "mms_pool"
    },
    {
      name  = "SPRING_SECOND_DATASOURCE_TYPE"
      value = "oracle.jdbc.pool.OracleDataSource"
    },
    #    {
    #      name  = "SCHEDULE_MERGEUNMERGE"
    #      value = local.merge_config["schedule"]
    #    },
    {
      name  = "SPRING_JPA_HIBERNATE_DDL_AUTO"
      value = "update"
    },
    {
      name  = "SPRING_BATCH_JOB_ENABLED"
      value = "false"
    },
    {
      name  = "SPRING_BATCH_INITIALIZE_SCHEMA"
      value = "always"
    },
    {
      name  = "ALFRESCO_DMS_PROTOCOL"
      value = "https"
    },
    #    {
    #      name  = "ALFRESCO_DMS_HOST"
    #      value = "alfresco.${data.terraform_remote_state.vpc.outputs.public_zone_name}"
    #    },
    {
      name  = "SECURITY_OAUTH2_RESOURCE_ID"
      value = "NDelius"
    },
    {
      name  = "SPRING_SECURITY_OAUTH2_RESOURCESERVER_OPAQUE_TOKEN_CLIENT_ID"
      value = "Merge-API"
    },
    {
      name  = "SPRING_SECURITY_OAUTH2_RESOURCESERVER_OPAQUE_TOKEN_INTROSPECTION_URI"
      value = "http://usermanagement.ecs.cluster:8080/umt/oauth/check_token"
    },
    #    {
    #      name  = "LOGGING_LEVEL_UK_GOV_JUSTICE"
    #      value = local.merge_config["log_level"]
    #    },
    #    {
    #      name  = "SPRING_FLYWAY_ENABLED"
    #      value = "true"
    #    },
    #    {
    #      name  = "SPRING_FLYWAY_LOCATIONS"
    #      value = "classpath:/db"
    #    }
  ]
}
