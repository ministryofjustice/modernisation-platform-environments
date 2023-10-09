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

  # TODO - change alarm actions to dba_pagerduty once alarms proven out
  xtag_cloudwatch_metric_alarms = merge(
    module.baseline_presets.cloudwatch_metric_alarms.ec2,
    module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
    module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd,
    {
      xtag-wls-nodemanager-service = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_wlsnodemanager_value"
        period              = "60"
        statistic           = "Average"
        threshold           = "1"
        alarm_description   = "wls_nodemanager.service has stopped"
        alarm_actions       = ["dso_pagerduty"]
      }
      xtag-wls-adminserver-service = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_wlsadminserver_value"
        period              = "60"
        statistic           = "Average"
        threshold           = "1"
        alarm_description   = "wls_adminserver.service has stopped"
        alarm_actions       = ["dso_pagerduty"]
      }
      xtag-wls-managedserver-service = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_wlsmanagedserver_value"
        period              = "60"
        statistic           = "Average"
        threshold           = "1"
        alarm_description   = "wls_managedserver.service has stopped"
        alarm_actions       = ["dso_pagerduty"]
      }
    }
  )

  xtag_ec2 = {
    autoscaling_group     = module.baseline_presets.ec2_autoscaling_group.default
    autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
    # cloudwatch_metric_alarms = local.xtag_cloudwatch_metric_alarms

    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name          = "nomis_rhel_7_9_weblogic_xtag_10_3_release_2023-07-19T09-01-29.168Z"
      availability_zone = null
    })

    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      instance_type          = "t2.large"
      vpc_security_group_ids = ["private-web"]
    })

    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible

    tags = {
      description = "nomis XTAG weblogic component"
      ami         = "nomis_rhel_7_9_weblogic_xtag_10_3"
      os-type     = "Linux"
      server-type = "nomis-xtag"
    }
  }
}
