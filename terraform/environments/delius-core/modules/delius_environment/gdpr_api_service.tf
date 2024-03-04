module "gdpr_api_service" {
  source = "../helpers/delius_microservice"

  name                  = "gdpr-api"
  certificate_arn       = local.certificate_arn
  alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  env_name              = var.env_name
  container_port_config = [
    {
      containerPort = var.delius_microservice_configs.gdpr_api.container_port
      protocol      = "tcp"
  }]
  ecs_cluster_arn = module.ecs.ecs_cluster_arn
  container_secrets = [
    {
      name      = "SPRING_DATASOURCE_PASSWORD"
      valueFrom = aws_ssm_parameter.delius_core_gdpr_db_admin_password.arn
      #value = "/${var.environment_name}/${var.project_name}/delius-gdpr-database/db/admin_password" # delete this
    },
    {
      name      = "SPRING_SECOND-DATASOURCE_PASSWORD"
      valueFrom = aws_ssm_parameter.delius_core_gdpr_db_pool_password.arn
      #value = "/${var.environment_name}/${var.project_name}/delius-database/db/gdpr_pool_password" # delete
    },
    {
      name      = "SECURITY_OAUTH2_CLIENT_CLIENT-SECRET"
      valueFrom = aws_ssm_parameter.delius_core_gdpr_api_client_secret.arn
      #value = "/${var.environment_name}/${var.project_name}/gdpr/api/client_secret" # delete
    }
  ]
  db_ingress_security_groups = []
  cluster_security_group_id  = aws_security_group.cluster.id

  bastion_sg_id                      = module.bastion_linux.bastion_security_group
  tags                               = var.tags
  microservice_lb                    = aws_lb.delius_core_frontend
  microservice_lb_https_listener_arn = aws_lb_listener.listener_https.arn
  alb_listener_rule_paths            = ["/gdpr/api", "/gdpr/api/*"]

  platform_vars     = var.platform_vars
  container_image   = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-gdpr-api-ecr-repo:${var.delius_microservice_configs.gdpr_api.image_tag}"
  account_config    = var.account_config
  health_check_path = "/gdpr/api/actuator/health"
  account_info      = var.account_info

  create_rds            = var.delius_microservice_configs.gdpr_api.create_rds
  rds_engine            = var.delius_microservice_configs.gdpr_api.rds_engine
  rds_engine_version    = var.delius_microservice_configs.gdpr_api.rds_engine_version
  rds_instance_class    = var.delius_microservice_configs.gdpr_api.rds_instance_class
  rds_port              = var.delius_microservice_configs.gdpr_api.rds_port
  rds_allocated_storage = var.delius_microservice_configs.gdpr_api.rds_allocated_storage
  rds_username          = var.delius_microservice_configs.gdpr_api.rds_username
  rds_license_model     = var.delius_microservice_configs.gdpr_api.rds_license_model

  container_environment_vars = [
    {
      name  = "SERVER_SERVLET_CONTEXT_PATH"
      value = "/gdpr/api/"
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
      value = "gdpr_pool"
    },
    {
      name  = "SPRING_SECOND_DATASOURCE_TYPE"
      value = "oracle.jdbc.pool.OracleDataSource"
    },
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
    #    {
    #      name  = "SCHEDULE_IDENTIFYDUPLICATES"
    #      value = local.gdpr_config["cron_identifyduplicates"]
    #    },
    #    {
    #      name  = "SCHEDULE_RETAINEDOFFENDERS"
    #      value = local.gdpr_config["cron_retainedoffenders"]
    #    },
    #    {
    #      name  = "SCHEDULE_RETAINEDOFFENDERSIICSA"
    #      value = local.gdpr_config["cron_retainedoffendersiicsa"]
    #    },
    #    {
    #      name  = "SCHEDULE_ELIGIBLEFORDELETION"
    #      value = local.gdpr_config["cron_eligiblefordeletion"]
    #    },
    #    {
    #      name  = "SCHEDULE_DELETEOFFENDERS"
    #      value = local.gdpr_config["cron_deleteoffenders"]
    #    },
    #    {
    #      name  = "SCHEDULE_DESTRUCTIONLOGCLEARING"
    #      value = local.gdpr_config["cron_destructionlogclearing"]
    #    },
    #    {
    #      name  = "SCHEDULE_ELIGIBLEFORDELETIONSOFTDELETED"
    #      value = local.gdpr_config["cron_eligiblefordeletionsoftdeleted"]
    #    },
    {
      name  = "SECURITY_OAUTH2_RESOURCE_ID"
      value = "NDelius"
    },
    {
      name  = "SECURITY_OAUTH2_CLIENT_CLIENT_ID"
      value = "GDPR-API"
    },
    {
      name  = "SECURITY_OAUTH2_RESOURCE_TOKEN_INFO_URI"
      value = "http://usermanagement.ecs.cluster:8080/umt/oauth/check_token"
    },
    #    {
    #      name  = "LOGGING_LEVEL_UK_GOV_JUSTICE"
    #      value = local.gdpr_config["log_level"]
    #    },
    {
      name  = "SPRING_FLYWAY_ENABLED"
      value = "true"
    },
    {
      name  = "SPRING_FLYWAY_LOCATIONS"
      value = "classpath:/db"
    }
  ]

  providers = {
    aws          = aws
    aws.core-vpc = aws.core-vpc
  }
}