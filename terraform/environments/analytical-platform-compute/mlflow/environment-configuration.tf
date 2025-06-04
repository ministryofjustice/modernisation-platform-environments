locals {
  environment_configurations = {
    development = {
      mlflow_s3_bucket_name = "alpha-analytical-platform-mlflow-development"
      route53_zone          = "compute.development.analytical-platform.service.justice.gov.uk"

    }
    test = {
      mlflow_s3_bucket_name = "alpha-analytical-platform-mlflow-test"
      route53_zone          = "compute.test.analytical-platform.service.justice.gov.uk"
    }
    production = {
      mlflow_s3_bucket_name = "alpha-analytical-platform-mlflow"
      route53_zone          = "compute.analytical-platform.service.justice.gov.uk"
    }
  }
}
