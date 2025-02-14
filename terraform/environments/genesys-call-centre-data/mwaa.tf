# Amazon Managed Workflows for Apache Airflow (MWAA)
resource "aws_mwaa_environment" "genesys" {
  name                            = local.environment
  airflow_version                 = local.environment_configuration.airflow_version
  environment_class               = local.environment_configuration.airflow_environment_class
  weekly_maintenance_window_start = local.environment_configuration.weekly_maintenance_window_start

  execution_role_arn = module.mwaa_execution_iam_role.iam_role_arn

  kms_key = module.mwaa_kms.key_arn

  source_bucket_arn         = module.s3_bucket_mwaa.s3_bucket_arn
  dag_s3_path               = local.environment_configuration.dag_s3_path
  requirements_s3_path      = local.environment_configuration.requirements_s3_path
  plugins_s3_path           = local.environment_configuration.plugins_s3_path
  plugins_s3_object_version = module.airflow_plugins_object.s3_object_version_id

  max_workers = local.environment_configuration.max_workers
  min_workers = local.environment_configuration.min_workers
  schedulers  = local.environment_configuration.schedulers

  webserver_access_mode = local.environment_configuration.webserver_access_mode

  airflow_configuration_options = {
    "webserver.warn_deployment_exposure" = 0
    "webserver.base_url"                 = "airflow.${local.environment_configuration.route53_zone}"
    "webserver.instance_name"            = local.environment_configuration.airflow_webserver_instance_name
  }

  network_configuration {
    security_group_ids = [module.mwaa_security_group.security_group_id]
    subnet_ids         = slice(module.vpc.private_subnets, 0, 2)
  }

  logging_configuration {
    dag_processing_logs {
      enabled   = true
      log_level = "INFO"
    }

    scheduler_logs {
      enabled   = true
      log_level = "INFO"
    }

    task_logs {
      enabled   = true
      log_level = "INFO"
    }

    webserver_logs {
      enabled   = true
      log_level = "INFO"
    }

    worker_logs {
      enabled   = true
      log_level = "INFO"
    }
  }

  tags = local.tags
}