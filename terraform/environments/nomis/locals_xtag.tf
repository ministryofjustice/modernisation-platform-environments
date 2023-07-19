locals {

  xtag_weblogic_ssm_parameters = {
    prefix = "/weblogic/"
    parameters = {
      admin_username = { description = "weblogic admin username" }
      admin_password = { description = "weblogic admin password" }
      db_username    = { description = "nomis database xtag username" }
      db_password    = { description = "nomis database xtag password" }
    }
  }

  xtag_ec2_default = {
    cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso_pagerduty"].ec2_linux_default

    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name          = "base_rhel_7_9_*"
      availability_zone = null
    })

    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      instance_type          = "t2.large"
      vpc_security_group_ids = ["private-web"]
    })

    user_data_cloud_init  = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
    autoscaling_group     = module.baseline_presets.ec2_autoscaling_group.default
    autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours

    tags = {
      description = "nomis XTAG weblogic component"
      ami         = "base_rhel_7_9"
      os-type     = "Linux"
      server-type = "nomis-xtag"
    }
  }

  xtag_ec2_a = merge(local.xtag_ec2_default, {
    cloudwatch_metric_alarms = {}
    config = merge(local.xtag_ec2_default.config, {
      ami_name = "base_rhel_7_9_*"
    })
    user_data_cloud_init = merge(local.xtag_ec2_default.user_data_cloud_init, {
      args = merge(local.xtag_ec2_default.user_data_cloud_init.args, {
        branch = "04d8c6102389cf9cd9f638d844c346d20c388bd9" # prior to AMI setup
      })
    })
    autoscaling_group = merge(local.xtag_ec2_default.autoscaling_group, {
    })
  })

  xtag_ec2_b = merge(local.xtag_ec2_default, {
    cloudwatch_metric_alarms = {}
    config = merge(local.xtag_ec2_default.config, {
      ami_name = "nomis_rhel_7_9_weblogic_xtag_10_3_release_2023-07-19T09-01-29.168Z"
    })
    user_data_cloud_init = merge(local.xtag_ec2_default.user_data_cloud_init, {
      args = merge(local.xtag_ec2_default.user_data_cloud_init.args, {
        branch = "nomis/DSOS-1990/xtag-bits-and-bobs"
      })
    })
    autoscaling_group = merge(local.xtag_ec2_default.autoscaling_group, {
      desired_capacity = 0
    })
    tags = merge(local.xtag_ec2_default.tags, {
      ami = "nomis_rhel_7_9_weblogic_xtag_10_3"
    })
  })

}
