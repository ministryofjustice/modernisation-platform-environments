locals {
  development_config = {

    baseline_s3_buckets = {

      # the shared image builder bucket is just created in development
      nomis-combined-reporting-software = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
          module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
      }
    }

    baseline_ec2_instances = {
      dev-redhat-rhel79-1 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name  = "RHEL-7.9_HVM-*"
          ami_owner = "309956199498"
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private"]
        })
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        tags = {
          description = "For testing with official RedHat RHEL7.9 image"
          os-type     = "Linux"
          component   = "test"
        }
      }
    }

    baseline_ec2_autoscaling_groups = {
      dev-redhat-rhel79 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name  = "RHEL-7.9_HVM-*"
          ami_owner = "309956199498"
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private"]
        })
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        autoscaling_group = {
          desired_capacity    = 1
          max_size            = 2
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "For testing with official RedHat RHEL7.9 image"
          os-type     = "Linux"
          component   = "test"
        }
      }
    }

    baseline_lbs = {
    }
  }
}
