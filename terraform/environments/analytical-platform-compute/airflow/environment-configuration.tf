locals {
  environment_configurations = {
    development = {
      /* Route53 */
      route53_zone = "compute.development.analytical-platform.service.justice.gov.uk"

      /* MWAA */
      airflow_version                 = "2.10.3"
      airflow_environment_class       = "mw1.small"
      airflow_webserver_instance_name = "Development"
    }
    test = {
      /* Route53 */
      route53_zone = "compute.test.analytical-platform.service.justice.gov.uk"

      /* MWAA */
      airflow_version                 = "2.10.3"
      airflow_environment_class       = "mw1.medium"
      airflow_webserver_instance_name = "Test"
    }
    production = {
      /* Route53 */
      route53_zone = "compute.analytical-platform.service.justice.gov.uk"

      /* MWAA */
      airflow_version                 = "2.10.3"
      airflow_environment_class       = "mw1.medium"
      airflow_webserver_instance_name = "Production"
    }
  }
}
