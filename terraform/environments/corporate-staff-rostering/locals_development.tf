# csr-development environment settings
locals {

  # baseline config
  development_config = {

    baseline_ec2_autoscaling_groups = {
      dev-base-ol85 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "base_ol_8_5_*"
          availability_zone = null
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["database"]
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
        tags = {
          description = "For testing our base OL8.5 base image"
          ami         = "base_ol_8_5"
          os-type     = "Linux"
          component   = "test"
          server-type = "base-ol-8-5"
        }
      }

      dev-tst = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "base_windows_server_2012_r2_release_2023-*"
          ami_owner                     = "374269020027"
          ebs_volumes_copy_all_from_ami = false
          instance_profile_policies     = concat(module.baseline_presets.ec2_instance.config.default.instance_profile_policies, ["CSRWebServerPolicy"])
          user_data_raw                 = base64encode(file("./templates/user-data.yaml"))
        })
        cloudwatch_metric_alarms = local.app_ec2_cloudwatch_metric_alarms
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["app", "domain", "jumpserver"]
          instance_type          = "t3.medium"
        })
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0 # set to 0 while testing
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 192 } # minimum size has to be 128 due to snapshot sizes
        }
        tags = {
          description = "Test AWS AMI Windows Server 2012 R2"
          os-type     = "Windows"
          component   = "appserver"
          server-type = "test-server"
        }
      }
    }

    baseline_ec2_instances = {
    }
    baseline_route53_zones = {
    }
  }
}
