locals {
  environment_configurations = {
    development = {
      /* Route53 */
      route53_zone = "compute.development.analytical-platform.service.justice.gov.uk"

      /* MWAA */
      airflow_version                 = "2.10.3"
      airflow_environment_class       = "mw1.large"
      airflow_webserver_instance_name = "Development"
      airflow_max_workers             = 10
      airflow_min_workers             = 2
      airflow_schedulers              = 2
      airflow_celery_worker_autoscale = "7,0"
    }
    test = {
      /* Route53 */
      route53_zone = "compute.test.analytical-platform.service.justice.gov.uk"

      /* MWAA */
      airflow_version                 = "2.10.3"
      airflow_environment_class       = "mw1.large"
      airflow_webserver_instance_name = "Test"
      airflow_max_workers             = 10
      airflow_min_workers             = 2
      airflow_schedulers              = 2
      airflow_celery_worker_autoscale = "7,0"
    }
    production = {
      /* Route53 */
      route53_zone = "compute.analytical-platform.service.justice.gov.uk"

      /* MWAA */
      airflow_version                 = "2.10.3"
      airflow_environment_class       = "mw1.large"
      airflow_webserver_instance_name = "Production"
      airflow_max_workers             = 10
      airflow_min_workers             = 2
      airflow_schedulers              = 2
      airflow_celery_worker_autoscale = "7,0"
    }
  }
}
