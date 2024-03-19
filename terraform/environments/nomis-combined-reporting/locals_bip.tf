locals {

  bip_secretsmanager_secrets = {
    secrets = {
      passwords = { description = "BIP Passwords" }
    }
  }

  bip_cloudwatch_metric_alarms = merge(
    module.baseline_presets.cloudwatch_metric_alarms.ec2,
    module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
    module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
    # module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app, # add in once there are custom services monitored
  )

  bip_cloudwatch_log_groups = {
    cwagent-bip-logs = {
      retention_in_days = 30
    }
  }

  bip_ec2_default = {

    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name                  = "base_rhel_8_5_*"
      ssm_parameters_prefix     = "bip/"
      iam_resource_names_prefix = "ec2-bip"
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      instance_type          = "t3.large"
      vpc_security_group_ids = ["private"]

      tags = {
        backup-plan = "daily-and-weekly"
      }
    })

    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible

    autoscaling_group = module.baseline_presets.ec2_autoscaling_group.default
    ebs_volumes = {
      "/dev/sdb" = { type = "gp3", size = 100 }
      "/dev/sdc" = { type = "gp3", size = 100 }
      "/dev/sds" = { type = "gp3", size = 100 }
    }

    tags = {
      description = "ncr bip webtier component"
      ami         = "base_rhel_8_5"
      backup      = "false" # opt out of mod platform default backup plan
      os-type     = "Linux"
      server-type = "ncr-bip"
      component   = "web"
    }
  }

}
