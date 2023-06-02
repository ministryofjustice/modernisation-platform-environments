locals {
  airflow_name                            = local.environment
  airflow_dag_s3_path                     = "dags/"
  airflow_requirements_s3_path            = "requirements.txt"
  airflow_webserver_access_mode           = "PUBLIC_ONLY"
  airflow_weekly_maintenance_window_start = "SAT:00:00"
  airflow_mail_from_address               = "airflow@${local.ses_domain_identity}"

  ses_domain_identity = "apps-tools.${local.environment}.data-platform.service.justice.gov.uk"

  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      airflow_version           = "2.4.3"
      airflow_environment_class = "mw1.medium"
      airflow_max_workers       = 10
      airflow_min_workers       = 1
      airflow_schedulers        = 2
      airflow_configuration_options = {
        "webserver.warn_deployment_exposure" = 0
      }
      eks_cluster_arn = "arn:aws:eks:eu-west-1:525294151996:cluster/development-aWrhyc0m"
    }
  }
}
