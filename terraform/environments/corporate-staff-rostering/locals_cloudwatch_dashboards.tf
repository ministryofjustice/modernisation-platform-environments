locals {

  cloudwatch_dashboard_widget_groups = {
    all_ec2 = {
      header_markdown = "## EC2 ALL"
      width           = 8
      height          = 8
      widgets = [
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.high-memory-usage,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_windows.high-memory-usage,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.instance-status-check-failed,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.system-status-check-failed,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.attached-ebs-status-check-failed,
      ]
      add_ebs_widgets = {
        iops       = true
        throughput = true
      }
    }

    all_windows_ec2 = {
      header_markdown = "## EC2 ALL"
      width           = 8
      height          = 8
      widgets = [
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_windows.high-memory-usage,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_windows.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.instance-status-check-failed,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.system-status-check-failed,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.attached-ebs-status-check-failed,
      ]
      add_ebs_widgets = {
        iops       = true
        throughput = true
      }
    }

    app = {
      header_markdown = "## EC2 App Tier"
      width           = 8
      height          = 8
      search_filter = {
        ec2_tag = [
          { tag_name = "component", tag_value = "app" },
        ]
      }
      widgets = [
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-in-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-out-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_windows.cpu-core-utilization-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_windows.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_windows.high-memory-usage,
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
          { tag_name = "component", tag_value = "data" },
        ]
      }
      widgets = [
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-in-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-out-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.high-memory-usage,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.cpu-iowait-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_linux.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_os.service-status-error-os-layer,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_app.service-status-error-app-layer,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_oracle_db_connected.oracle-db-disconnected,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_oracle_db_backup.oracle-db-rman-backup-error,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_oracle_db_backup.oracle-db-rman-backup-did-not-run,
      ]
    }

    web = {
      header_markdown = "## EC2 Web Tier"
      width           = 8
      height          = 8
      search_filter = {
        ec2_tag = [
          { tag_name = "component", tag_value = "web" },
        ]
      }
      widgets = [
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-in-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-out-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_windows.cpu-core-utilization-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_windows.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_windows.high-memory-usage,
      ]
    }

  }
}

