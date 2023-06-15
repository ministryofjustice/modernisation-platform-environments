# nomis-test environment settings
locals {

  # baseline config
  test_config = {

    baseline_ec2_autoscaling_groups = {
      mrj-dev-base-ol85 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "base_ol_8_5_*"
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["data-db"]
        })
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        tags = {
          description = "For testing our base OL8.5 base image"
          ami         = "base_ol_8_5"
          os-type     = "Linux"
          component   = "test"
          server-type = "base-ol-8-5"
        }
      }
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
