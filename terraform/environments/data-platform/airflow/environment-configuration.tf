locals {
  environment_configurations = {
    test = {
      /* Route53 */
      route53_zone = "test.data-platform.service.justice.gov.uk"

      /* MWAA */
      airflow_version                 = "3.3.1"
      airflow_environment_class       = "mw1.large"
      airflow_webserver_instance_name = "Test"
      airflow_max_workers             = 10
      airflow_min_workers             = 2
      airflow_schedulers              = 2
      airflow_celery_worker_autoscale = "7,1"
      airflow_dagbag_import_timeout   = 60
    }
  }
}
