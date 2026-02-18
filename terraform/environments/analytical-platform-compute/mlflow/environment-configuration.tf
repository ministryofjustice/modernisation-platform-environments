locals {
  environment_configurations = {
    development = {
      mlflow_s3_bucket_name = "alpha-analytical-platform-mlflow-development"
      route53_zone          = "compute.development.analytical-platform.service.justice.gov.uk"

    }
    test = {
    }
    production = {
    }
  }
}
