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

      # >>> TEMPORARY (Airflow 3 durability test): START
      /* Airflow workflow access to the MWAA bucket
         Prefix => workflow IAM role names. The roles are created by
         ministryofjustice/analytical-platform-airflow in analytical-platform-data-production,
         and must exist before this is applied (S3 and KMS reject unknown principals). */
      mwaa_bucket_workflow_access = {
        "durability-test" = [
          "airflow-dp-test-data-platform-example-durability-producer",
          "airflow-dp-test-data-platform-example-durability-consumer",
        ]
      }
      # <<< TEMPORARY (Airflow 3 durability test): END
    }
  }
}
