# nomis-development environment settings
locals {

  # baseline config
  development_config = {

    baseline_secretsmanager_secrets = {
      "/oracle/oem"                = local.oem_secretsmanager_secrets
      "/oracle/database/EMREP"     = local.oem_secretsmanager_secrets
      "/oracle/database/DEVRCVCAT" = local.oem_secretsmanager_secrets
    }

    baseline_ec2_autoscaling_groups = {
      dev-base-ol85 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "base_ol_8_5_*"
          availability_zone = null
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["data-oem"]
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "main"
          })
        })
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        # autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "For testing our base OL8.5 base image"
          ami         = "base_ol_8_5"
          os-type     = "Linux"
          component   = "test"
          server-type = "base-ol-8-5"
        }
      }
    }

    baseline_ec2_instances = {
      dev-oem-a = merge(local.oem_ec2_default, {
        config = merge(local.oem_ec2_default.config, {
          availability_zone = "eu-west-2a"
        })
        user_data_cloud_init = merge(local.oem_ec2_default.user_data_cloud_init, {
          args = merge(local.oem_ec2_default.user_data_cloud_init.args, {
            branch = "45027fb7482eb7fb601c9493513bb73658780dda" # 2023-08-11
          })
        })
        tags = merge(local.oem_ec2_default.tags, {
          oracle-sids = "EMREP DEVRCVCAT"
        })
      })
    }
  }
}
