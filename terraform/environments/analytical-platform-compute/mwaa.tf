resource "aws_mwaa_environment" "main" {
  name                            = local.environment
  airflow_version                 = local.environment_configuration.airflow_version
  environment_class               = local.environment_configuration.airflow_environment_class
  weekly_maintenance_window_start = "SAT:01:00"

  execution_role_arn = module.mwaa_execution_iam_role.iam_role_arn

  kms_key = module.mwaa_kms.key_arn

  source_bucket_arn              = module.mwaa_bucket.s3_bucket_arn
  dag_s3_path                    = "dags/"
  requirements_s3_path           = "requirements.txt"
  requirements_s3_object_version = module.airflow_requirements_object.s3_object_version_id

  max_workers = 2
  min_workers = 1
  schedulers  = 2

  webserver_access_mode = "PRIVATE_ONLY"

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
}
