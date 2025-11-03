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
  plugins_s3_path                = "plugins.zip"
  plugins_s3_object_version      = module.airflow_plugins_object.s3_object_version_id

  max_workers = local.environment_configuration.airflow_max_workers
  min_workers = local.environment_configuration.airflow_min_workers
  schedulers  = local.environment_configuration.airflow_schedulers

  webserver_access_mode = "PRIVATE_ONLY"

  airflow_configuration_options = {
    "secrets.backend"                    = "airflow.providers.amazon.aws.secrets.secrets_manager.SecretsManagerBackend"
    "secrets.backend_kwargs"             = "{\"connections_prefix\": \"airflow/connections\", \"variables_prefix\": \"airflow/variables\"}"
    "smtp.smtp_host"                     = "email-smtp.${data.aws_region.current.region}.amazonaws.com"
    "smtp.smtp_port"                     = 587
    "smtp.smtp_starttls"                 = 1
    "smtp.smtp_user"                     = module.mwaa_ses_iam_user.iam_access_key_id
    "smtp.smtp_password"                 = module.mwaa_ses_iam_user.iam_access_key_ses_smtp_password_v4
    "smtp.smtp_mail_from"                = "noreply@${local.environment_configuration.route53_zone}"
    "webserver.warn_deployment_exposure" = 0
    "webserver.base_url"                 = "airflow.${local.environment_configuration.route53_zone}"
    "webserver.instance_name"            = local.environment_configuration.airflow_webserver_instance_name
    "celery.worker_autoscale"            = local.environment_configuration.airflow_celery_worker_autoscale
  }

  network_configuration {
    security_group_ids = [module.mwaa_security_group.security_group_id]
    subnet_ids = [
      data.aws_subnet.apc_private_subnet_a.id,
      data.aws_subnet.apc_private_subnet_b.id
    ]
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

  worker_replacement_strategy = local.environment_configuration.airflow_worker_replacement_strategy

  tags = local.tags
}
