locals {

  baseline_presets_development = {
    options = {
    }
  }

  # please keep resources in alphabetical order
  baseline_development = {

    ec2_autoscaling_groups = {
      dev-web-asg = merge(local.defaults_web_ec2.config, {
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        config = merge(local.defaults_web_ec2.config, {
          availability_zone = "eu-west-2a"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "t3.large"
        })
        user_data_cloud_init = merge(local.defaults_web_ec2.user_data_cloud_init, {
          args = merge(local.defaults_web_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
      })

      dev-boe-asg = merge(local.defaults_boe_ec2, {
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        config = merge(local.defaults_boe_ec2.config, {
          availability_zone = "eu-west-2a"
        })
        instance = merge(local.defaults_boe_ec2.instance, {
          instance_type = "t2.large"
        })
        user_data_cloud_init = merge(local.defaults_web_ec2.user_data_cloud_init, {
          args = merge(local.defaults_web_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
      })

      dev-bods-asg = merge(local.defaults_bods_ec2, {
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        config = merge(local.defaults_bods_ec2.config, {
          availability_zone = "eu-west-2a"
        })
        instance = merge(local.defaults_bods_ec2.instance, {
          instance_type = "t3.large"
        })
      })
    }

    ec2_instances = {
      #   dev-web-a = merge(local.defaults_web_ec2,
      #   {
      #     config = merge(local.defaults_web_ec2.config, {
      #       availability_zone = "eu-west-2a"
      #     })
      #     instance = merge(local.defaults_web_ec2.instance, {
      #       instance_type = "t3.large"
      #     })
      #   })
      #   dev-boe-a = merge(local.defaults_boe_ec2,
      #   {
      #     config = merge(local.defaults_boe_ec2.config, {
      #       availability_zone = "eu-west-2a"
      #     })
      #     instance = merge(local.defaults_boe_ec2.instance, {
      #       instance_type = "t2.large"
      #     })
      #     user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
      #       args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
      #         branch = "main"
      #       })
      #     })
      #   })
      #   dev-bods-a = merge(local.defaults_bods_ec2,
      #   {
      #     config = merge(local.defaults_bods_ec2.config, {
      #       availability_zone = "eu-west-2a"
      #     })
      #     instance = merge(local.defaults_bods_ec2.instance, {
      #       instance_type = "t3.large"
      #     })
      #   })
    }

    route53_zones = {
      "development.reporting.oasys.service.justice.gov.uk" = {}
    }
  }
}

