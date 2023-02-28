locals {

  baseline_s3_buckets = {
    s3-bucket = {
      iam_policies = module.baseline_presets.s3_iam_policies
    }

    #    ec2-image-builder-nomis-combined-reporting = {
    #      custom_kms_key = module.environment.kms_keys["general"].arn
    #      bucket_policy_v2 = [
    #        module.baseline_presets.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
    #        module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy
    #      ]
    #      iam_policies = module.baseline_presets.s3_iam_policies
    #    }
    #  }

  }
}
