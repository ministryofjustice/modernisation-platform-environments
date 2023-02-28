locals {
  development_config = {
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
