locals {

  baseline_presets_test = {
    options = {}
  }

  # please keep resources in alphabetical order
  baseline_test = {

    route53_zones = {
      "test.planetfm.service.justice.gov.uk" = {}
    }

    s3_buckets = {
      # use this bucket for storing artefacts for use across all accounts
      planetfm-software = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
          module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy,
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
      }
    }
  }
}
