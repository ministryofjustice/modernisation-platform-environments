locals {

  tomcat_secretsmanager_secrets = {
    secrets = {
      passwords = { description = "Tomcat Passwords" }
    }
  }

  tomcat_cloudwatch_metric_alarms = merge(
    module.baseline_presets.cloudwatch_metric_alarms.ec2,
    module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
    module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
    # module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app, # add in once there are custom services monitored
  )

  tomcat_cloudwatch_log_groups = {
    cwagent-tomcat-logs = {
      retention_in_days = 30
    }
  }

  tomcat_ec2_default = {

    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name                  = "base_rhel_8_5_*"
      ssm_parameters_prefix     = "tomcat/"
      iam_resource_names_prefix = "ec2-tomcat"
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
    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible

    autoscaling_group = module.baseline_presets.ec2_autoscaling_group.default

    lb_target_groups = {
      http-7777 = local.tomcat_target_group_http_7777
      http-7010 = local.tomcat_target_group_http_7010
      http-8443 = local.tomcat_target_group_http_8443
      http-8005 = local.tomcat_target_group_http_8005
    }

    tags = {
      description = "ncr tomcat webtier component"
      ami         = "base_rhel_8_5"
      os-type     = "Linux"
      server-type = "ncr-tomcat"
      component   = "web"
    }
  }

}
