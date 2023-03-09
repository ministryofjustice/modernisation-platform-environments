locals {

  # remove once software copied from nomis-test
  test_s3_policies = {
    NomisTestWriteAccessBucketPolicy = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:ListBucket"
      ]
      principals = {
        type = "AWS"
        identifiers = [
          module.environment.account_root_arns["nomis-test"]
        ]
      }
    }
  }

  test_config = {

    baseline_s3_buckets = {

      # the shared image builder bucket is just created in development
      nomis-data-hub-software = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
          module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy,
          local.test_s3_policies.NomisTestWriteAccessBucketPolicy
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
      }
    }
  }
}
