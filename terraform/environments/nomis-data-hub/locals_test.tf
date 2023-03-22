locals {
  test_config = {

    baseline_s3_buckets = {

      # the shared image builder bucket is just created in one account
      nomis-data-hub-software = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
          module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy,
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
      }
    }

    baseline_ec2_instances = {
      # Example instance using RedHat image with ansible provisioning
      # dev-redhat-rhel79-1 = {
      #   config = merge(module.baseline_presets.ec2_instance.config.default, {
      #     ami_name  = "RHEL-7.9_HVM-*"
      #     ami_owner = "309956199498"
      #   })
      #   instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      #     vpc_security_group_ids = ["private"]
      #   })
      #   user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
      #   tags = {
      #     description = "For testing with official RedHat RHEL7.9 image"
      #     os-type     = "Linux"
      #     component   = "test"
      #     server-type = "set me to the ansible server type group vars"
      #   }
      # }


      t1_ndh_app_1 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name  = "base_rhel_7_9_*"
          ami_owner = "374269020027"
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private"]
        })
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        tags = {
          description = "Standalone EC2 for testing RHEL7.9 NDH App"
          os-type     = "Linux"
          component   = "ndh"
          server-type = "ndh-app"
          monitored   = false
        }
      }

      t1_ndh_ems_1 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name  = "base_rhel_7_9_*"
          ami_owner = "374269020027"
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private"]
        })
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        tags = {
          description = "Standalone EC2 for testing RHEL7.9 NDH App"
          os-type     = "Linux"
          component   = "ndh"
          server-type = "ndh-ems"
          monitored   = false
        }
      }
    }
    baseline_ec2_autoscaling_group = {

      # Example ASG using base image with ansible provisioning
      # Include the autoscale-trigger-hook ansible role when using hooks
      # dev-base-rhel79 = {
      #   config = merge(module.baseline_presets.ec2_instance.config.default, {
      #     ami_name = "base_rhel_7_9_*"
      #   })
      #   instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      #     vpc_security_group_ids = ["private"]
      #   })
      #   user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
      #   autoscaling_group = {
      #     desired_capacity    = 1
      #     max_size      #       # = 2
      #     vpc_zone_identifier = module.environment.subnets["private"].ids
      #   }
      #   autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
      #   tags = {
      #     description = "For testing with official RedHat RHEL7.9 image"
      #     os-type     = "Linux"
      #     component   = "test"
      #     server-type = "set me to the ansible server type group vars"
      #   }


      t1_ndh_app = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name  = "base_rhel_7_9_*"
          ami_owner = "374269020027"
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
          description = "Standalone EC2 for testing RHEL7.9 NDH App"
          os-type     = "Linux"
          component   = "ndh"
          server-type = "ndh-app"
          monitored   = false
        }
      }

      t1_ndh_ems = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name  = "base_rhel_7_9_*"
          ami_owner = "374269020027"
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
          description = "Standalone EC2 for testing RHEL7.9 NDH ems"
          os-type     = "Linux"
          component   = "ndh"
          server-type = "ndh-ems"
          monitored   = false
        }
      }
    }
  }
}
