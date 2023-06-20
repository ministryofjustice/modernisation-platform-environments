# nomis-test environment settings
locals {

  # baseline config
  test_config = {

    baseline_ec2_autoscaling_groups = {
      test-oem = merge(local.oem_ec2_default, {
        user_data_cloud_init = merge(local.oem_ec2_default.user_data_cloud_init, {
          args = merge(local.oem_ec2_default.user_data_cloud_init.args, {
            branch       = "feature/oracle-19c-fixes"
            ansible_args = "" # don't use the default tags since we aren't using oracle 19c AMI
          })
        })
      })
    }

    baseline_s3_buckets = {
      # use this bucket for storing artefacts for use across all accounts
      hmpps-oem-software = {
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
