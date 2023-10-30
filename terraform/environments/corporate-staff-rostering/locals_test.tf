# nomis-test environment settings
locals {

  # baseline config
  test_config = {

    baseline_ec2_instances = {}

    baseline_ec2_autoscaling_groups = {}

    baseline_route53_zones = {
      "test.csr.service.justice.gov.uk" = {}
    }

    baseline_s3_buckets = {
      # use this bucket for storing artefacts for use across all accounts
      csr-software = {
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
