locals {

  cloudwatch_dashboard_widget_groups = {
    all_ec2 = {
      header_markdown = "## EC2 ALL"
      width           = 8
      height          = 8
      widgets = [
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.high-memory-usage,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.cpu-iowait-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_filesystems_check.filesystems-check-error,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_filesystems_check.filesystems-check-metric-not-updated,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.instance-status-check-failed,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.system-status-check-failed,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.attached-ebs-status-check-failed,
      ]
      add_ebs_widgets = {
        iops       = true
        throughput = true
      }
    }

    cms = {
      header_markdown = "## EC2 BIP CMS"
      width           = 8
      height          = 8
      search_filter = {
        ec2_tag = [
          { tag_name = "server-type", tag_value = "onr-bip-cms" },
        ]
      }
      widgets = [
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.high-memory-usage,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.cpu-iowait-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-in-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-out-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_linux.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_os.service-status-error-os-layer,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_app.service-status-error-app-layer,
      ]
    }

    web = {
      header_markdown = "## EC2 BIP WEB"
      width           = 8
      height          = 8
      search_filter = {
        ec2_tag = [
          { tag_name = "server-type", tag_value = "onr-web" },
        ]
      }
      widgets = [
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.high-memory-usage,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.cpu-iowait-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_linux.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-in-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-out-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_linux.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_os.service-status-error-os-layer,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_app.service-status-error-app-layer,
      ]
    }

    bods = {
      header_markdown = "## EC2 BODS"
      width           = 8
      height          = 8
      search_filter = {
        ec2_tag = [
          { tag_name = "server-type", tag_value = "Bods" },
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
