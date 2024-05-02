locals {

  # baseline config
  development_config = {

    baseline_ec2_instances = {
      #   dev-web-a = merge(local.defaults_web_ec2, 
      #   {
      #     config = merge(local.defaults_web_ec2.config, {
      #       availability_zone = "${local.region}a"        
      #     })
      #     instance = merge(local.defaults_web_ec2.instance, {
      #       instance_type = "t3.large"
      #     })
      #   })
      #   dev-boe-a = merge(local.defaults_boe_ec2, 
      #   {
      #     config = merge(local.defaults_boe_ec2.config, {
      #       availability_zone = "${local.region}a"        
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
      #       availability_zone = "${local.region}a"        
      #     })
      #     instance = merge(local.defaults_bods_ec2.instance, {    
      #       instance_type = "t3.large"  
      #     })
      #   })
    }

    baseline_ec2_autoscaling_groups = {
      dev-web-asg = merge(local.defaults_web_ec2.config, {
        config = merge(local.defaults_web_ec2.config, {
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "t3.large"
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "main"
          })
        })
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
      })
      dev-boe-asg = merge(local.defaults_boe_ec2, {
        config = merge(local.defaults_boe_ec2.config, {
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_boe_ec2.instance, {
          instance_type = "t2.large"
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "main"
          })
        })
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
      })
      dev-bods-asg = merge(local.defaults_bods_ec2, {
        config = merge(local.defaults_bods_ec2.config, {
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_bods_ec2.instance, {
          instance_type = "t3.large"
        })
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
      })
    }
    baseline_route53_zones = {
      "development.reporting.oasys.service.justice.gov.uk" = {}
    }
  }
}

