locals {

  cloudwatch_dashboard_widget_groups = {
    asg = {
      header_markdown = "## EC2 ASG (WEB and WINDOWS CLIENT)"
      width           = 8
      height          = 8
      search_filter = {
        negate = true
        ec2_tag = [
          { tag_name = "server-type", tag_value = "nomis-build" },
          { tag_name = "server-type", tag_value = "nomis-db" },
          { tag_name = "server-type", tag_value = "nomis-db19c" },
          { tag_name = "server-type", tag_value = "nomis-web" },
          { tag_name = "server-type", tag_value = "nomis-web19c" },
          { tag_name = "server-type", tag_value = "nomis-xtag" },
          { tag_name = "server-type", tag_value = "NomisClient" },
        ]
      }
      widgets = [
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-in-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-out-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.instance-status-check-failed,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.system-status-check-failed,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.attached-ebs-status-check-failed,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.cpu-iowait-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.high-memory-usage,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_autoscaling_group_cwagent_linux.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_autoscaling_group_cwagent_collectd_service_status_os.service-status-error-os-layer,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_autoscaling_group_cwagent_collectd_service_status_app.service-status-error-app-layer,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_windows.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_windows.high-memory-usage,
        null,
      ]
    }

    connectivity = {
      header_markdown = "## Connectivity"
      width           = 8
      height          = 8
      widgets = [
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_connectivity_test.connectivity-test-all-failed,
        null,
        null
      ]
    }

    db = {
      header_markdown = "## EC2 Oracle Database"
      width           = 8
      height          = 8
      add_ebs_widgets = {
        iops       = true
        throughput = true
      }
      search_filter = {
        ec2_tag = [
          { tag_name = "server-type", tag_value = "nomis-db" },
          { tag_name = "server-type", tag_value = "nomis-db19c" },
        ]
      }
      widgets = [
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-in-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-out-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.instance-status-check-failed,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.system-status-check-failed,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.attached-ebs-status-check-failed,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.high-memory-usage,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.cpu-iowait-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_linux.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_os.service-status-error-os-layer,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_app.service-status-error-app-layer,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_oracle_db_connected.oracle-db-disconnected,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_oracle_db_backup.oracle-db-rman-backup-error,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_oracle_db_backup.oracle-db-rman-backup-did-not-run,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_textfile_monitoring.textfile-monitoring-metric-error,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_textfile_monitoring.textfile-monitoring-metric-not-updated,
        null
      ]
    }

    syscon = {
      header_markdown = "## EC2 SYSCON BUILD and WEB"
      width           = 8
      height          = 8
      search_filter = {
        ec2_tag = [
          { tag_name = "server-type", tag_value = "nomis-build" },
          { tag_name = "server-type", tag_value = "nomis-web" },
          { tag_name = "server-type", tag_value = "nomis-web19c" },
        ]
      }
      widgets = [
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-in-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-out-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.instance-status-check-failed,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.system-status-check-failed,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.attached-ebs-status-check-failed,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.high-memory-usage,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.cpu-iowait-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_linux.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_os.service-status-error-os-layer,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_app.service-status-error-app-layer,
      ]
    }

    xtag = {
      header_markdown = "## EC2 XTAG"
      width           = 8
      height          = 8
      search_filter = {
        ec2_tag = [
          { tag_name = "server-type", tag_value = "nomis-xtag" },
        ]
      }
      widgets = [
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-in-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-out-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.instance-status-check-failed,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.system-status-check-failed,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.attached-ebs-status-check-failed,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.high-memory-usage,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.cpu-iowait-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_linux.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_os.service-status-error-os-layer,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_app.service-status-error-app-layer,
      ]
    }
  }
}
