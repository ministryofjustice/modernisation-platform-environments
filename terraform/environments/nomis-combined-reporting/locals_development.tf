locals {
  development_config = {
    baseline_s3_buckets = {
      ncr-db-backup-bucket = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        iam_policies   = module.baseline_presets.s3_iam_policies
      }
    }
    baseline_route53_zones = {
      "development.reporting.nomis.service.justice.gov.uk" = {
      }
    }
  }
}
