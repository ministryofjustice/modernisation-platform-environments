locals {

  xtag_cloudwatch_metric_alarms = merge(
    module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dso_pagerduty"].ec2,
    module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dso_pagerduty"].ec2_cwagent_linux,
    module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dso_pagerduty"].ec2_instance_cwagent_collectd_service_status_os,
    module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2_instance_cwagent_collectd_service_status_app,
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
