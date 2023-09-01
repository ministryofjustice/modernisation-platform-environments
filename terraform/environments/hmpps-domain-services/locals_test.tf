# nomis-test environment settings
locals {

  # baseline config
  test_config = {


    baseline_ec2_autoscaling_groups = {

      test-redhat-rhel85 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "hmpps_rhel_8_5-*"
          ami_owner         = "161282055413"
          availability_zone = null
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-web"]
        })
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        autoscaling_group    = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags                  = {
          description = "For testing connection to Azure domain"
          os-type     = "Linux"
          component   = "test"
        }
      }
    }
  }
}