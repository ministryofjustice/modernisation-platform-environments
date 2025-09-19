locals {

  cloudwatch_metric_alarms = {
    bip_app = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_linux,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
      # module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app, # add in once there are custom services monitored
    )
    bip_web = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_linux,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
      # module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app, # add in once there are custom services monitored
    )
    db = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_linux,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app,
    )
    db_connected = merge(
      # DBAs have slack integration via OEM for this so don't include pagerduty integration
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_oracle_db_connected,
    )
    db_backup = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_oracle_db_backup,
    )
  }
}
