locals {
  environment_configurations = {
    development = {
      /* Route53 */
      route53_zone = "compute.development.analytical-platform.service.justice.gov.uk"

      /* MWAA */
      airflow_version                 = "2.10.3"
      airflow_environment_class       = "mw1.small"
      airflow_webserver_instance_name = "Development"
      weekly_maintenance_window_start = "SAT:01:00"

      dag_s3_path          = "dags/"
      requirements_s3_path = "requirements.txt"
      plugins_s3_path      = "plugins.zip"

      max_workers = 2
      min_workers = 1
      schedulers  = 2

      webserver_access_mode = "PRIVATE_ONLY"
    }
    production = {
      /* Route53 */
      route53_zone = "compute.analytical-platform.service.justice.gov.uk"

      /* MWAA */
      airflow_version                 = "2.10.3"
      airflow_environment_class       = "mw1.medium"
      airflow_webserver_instance_name = "Production"
      weekly_maintenance_window_start = "SAT:01:00"

      dag_s3_path          = "dags/"
      requirements_s3_path = "requirements.txt"
      plugins_s3_path      = "plugins.zip"

      max_workers = 2
      min_workers = 1
      schedulers  = 2

      webserver_access_mode = "PRIVATE_ONLY"
    }
  }
}