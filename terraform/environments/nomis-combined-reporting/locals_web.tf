locals {

  web_secretsmanager_secrets = {
    secrets = {
      passwords = { description = "Web Passwords" }
    }
  }

  web_cloudwatch_metric_alarms = merge(
    module.baseline_presets.cloudwatch_metric_alarms.ec2,
    module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
    module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
    # module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app, # add in once there are custom services monitored
  )

  web_cloudwatch_log_groups = {
    cwagent-web-logs = {
      retention_in_days = 30
    }
  }

  web_ec2_default = {

    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name                  = "base_rhel_8_5_*"
      ssm_parameters_prefix     = "web/"
      iam_resource_names_prefix = "ec2-web"
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      instance_type          = "t3.large"
      vpc_security_group_ids = ["private"]
    })
    ebs_volumes = {
      "/dev/sdb" = { type = "gp3", size = 100 }
      "/dev/sdc" = { type = "gp3", size = 100 }
      "/dev/sds" = { type = "gp3", size = 100 }
    }
    route53_records      = module.baseline_presets.ec2_instance.route53_records.internal_and_external
    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible

    tags = {
      description = "ncr bip web-tier component"
      ami         = "base_rhel_8_5"
      os-type     = "Linux"
      server-type = "ncr-web"
      component   = "web"
    }
  }

}
