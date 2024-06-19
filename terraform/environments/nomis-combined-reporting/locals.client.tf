locals {

  client_secretsmanager_secrets = {
    secrets = {
      passwords = { description = "Client Passwords" }
    }
  }

  client_cloudwatch_metric_alarms = merge(
    module.baseline_presets.cloudwatch_metric_alarms.ec2,
    module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
    module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
    # module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app, # add in once there are custom services monitored
  )

  client_cloudwatch_log_groups = {
    cwagent-client-logs = {
      retention_in_days = 30
    }
  }

  client_ec2_default = {

    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name                      = "hmpps_windows_server_2019_release_*"
      iam_resource_names_prefix     = "ec2-client"
      ebs_volumes_copy_all_from_ami = false
      user_data_raw                 = module.baseline_presets.ec2_instance.user_data_raw["user-data-pwsh"]
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      instance_type          = "t3.large"
      vpc_security_group_ids = ["private-jumpserver"]
    })

    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible

    ebs_volumes = {
      "/dev/sda1" = { type = "gp3", size = 100 }
    }
    route53_records = module.baseline_presets.ec2_instance.route53_records.internal_and_external

    tags = {
      description            = "Client Tools component"
      ami                    = "windows_server_2019"
      os-type                = "Windows"
      server-type            = "client"
      component              = "client"
      instance-access-policy = "full"
    }
  }
}
