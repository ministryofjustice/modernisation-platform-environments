module "merge_api_service" {
  source                = "../helpers/delius_microservice"
  name                  = "merge-api"
  certificate_arn       = local.certificate_arn
  alb_security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  env_name              = var.env_name
  container_port_config = [
    {
      containerPort = var.delius_microservice_configs.merge_api.container_port
      protocol      = "tcp"
    }
  ]
  ecs_cluster_arn = module.ecs.ecs_cluster_arn

  desired_count = 0

  db_ingress_security_groups = []
  cluster_security_group_id  = aws_security_group.cluster.id

  bastion_sg_id                      = module.bastion_linux.bastion_security_group
  tags                               = var.tags
  microservice_lb                    = aws_lb.delius_core_frontend
  microservice_lb_https_listener_arn = aws_lb_listener.listener_https.arn

  alb_listener_rule_paths = ["/merge/api", "/merge/api/*"]
  platform_vars           = var.platform_vars
  container_image         = "${var.platform_vars.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/delius-core-merge-api-ecr-repo:${var.delius_microservice_configs.merge_api.image_tag}"
  account_config          = var.account_config
  health_check_path       = "/merge/api/actuator/health"
  account_info            = var.account_info

  create_rds                  = var.delius_microservice_configs.merge_api.create_rds
  rds_engine                  = var.delius_microservice_configs.merge_api.rds_engine
  rds_engine_version          = var.delius_microservice_configs.merge_api.rds_engine_version
  rds_instance_class          = var.delius_microservice_configs.merge_api.rds_instance_class
  rds_port                    = var.delius_microservice_configs.merge_api.rds_port
  rds_allocated_storage       = var.delius_microservice_configs.merge_api.rds_allocated_storage
  rds_username                = var.delius_microservice_configs.merge_api.rds_username
  rds_license_model           = var.delius_microservice_configs.merge_api.rds_license_model
  rds_deletion_protection     = var.delius_microservice_configs.merge_api.rds_deletion_protection
  snapshot_identifier         = data.aws_ssm_parameter.merge_api_snapshot_identifier.value
  rds_skip_final_snapshot     = var.delius_microservice_configs.merge_api.rds_skip_final_snapshot
  maintenance_window          = var.delius_microservice_configs.merge_api.maintenance_window
  rds_backup_retention_period = var.delius_microservice_configs.merge_api.rds_backup_retention_period
  rds_backup_window           = var.delius_microservice_configs.merge_api.rds_backup_window

  container_vars_default = {
    "SERVER_SERVLET_CONTEXT_PATH" : "/merge/api/",
    "SPRING_DATASOURCE_DRIVER_CLASS_NAME" : "org.postgresql.Driver",
    "SPRING_SECOND_DATASOURCE_USERNAME" : "mms_pool",
    "SPRING_SECOND_DATASOURCE_TYPE" : "oracle.jdbc.pool.OracleDataSource",
    "SPRING_JPA_HIBERNATE_DDL_AUTO" : "update",
    "SPRING_BATCH_JOB_ENABLED" : "false",
    "SPRING_BATCH_INITIALIZE_SCHEMA" : "always",
    "ALFRESCO_DMS_PROTOCOL" : "https",
    "SECURITY_OAUTH2_RESOURCE_ID" : "NDelius",
    "SPRING_SECURITY_OAUTH2_RESOURCESERVER_OPAQUE_TOKEN_CLIENT_ID" : "Merge-API",
    "SPRING_SECURITY_OAUTH2_RESOURCESERVER_OPAQUE_TOKEN_INTROSPECTION_URI" : "http://usermanagement.ecs.cluster:8080/umt/oauth/check_token"
  }

  container_vars_env_specific = try(var.delius_microservice_configs.merge_api.container_vars_env_specific, {})

  container_secrets_default = {
    "SPRING_DATASOURCE_PASSWORD" : aws_ssm_parameter.delius_core_merge_db_admin_password.arn,
    "SPRING_SECOND-DATASOURCE_PASSWORD" : aws_ssm_parameter.delius_core_merge_db_pool_password.arn,
    "SPRING_SECURITY_OAUTH2_RESOURCESERVER_OPAQUE-TOKEN_CLIENT-SECRET" : aws_ssm_parameter.delius_core_merge_api_client_secret.arn
  }

  container_secrets_env_specific = try(var.delius_microservice_configs.merge_api.container_secrets_env_specific, {})


  ignore_changes_service_task_definition = true

  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  log_error_pattern       = "ERROR"
  sns_topic_arn           = aws_sns_topic.delius_core_alarms.arn
  frontend_lb_arn_suffix  = aws_lb.delius_core_frontend.arn_suffix
  enable_platform_backups = var.enable_platform_backups
}

#######################
#   Merge API Params  #
#######################

resource "aws_ssm_parameter" "merge_api_snapshot_identifier" {
  name  = "/delius-core-${var.env_name}/merge-api/snapshot_id"
  type  = "String"
  value = "DEFAULT"
  lifecycle {
    ignore_changes = [value]
  }
}

data "aws_ssm_parameter" "merge_api_snapshot_identifier" {
  name = aws_ssm_parameter.merge_api_snapshot_identifier.name
}
