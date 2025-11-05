locals {

  cloudwatch_dashboard_widget_groups = {
    all_ec2 = {
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

    jump = {
      header_markdown = "## EC2 JumpServer Tier"
      width           = 8
      height          = 8
      search_filter = {
        ec2_tag = [
          { tag_name = "server-type", tag_value = "HmppsJump2022" },
        ]
      }
      widgets = [
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-in-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-out-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_windows.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_windows.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_windows.high-memory-usage,
      ]
    }

    rdgateway = {
      header_markdown = "## EC2 RDGateway Tier"
      width           = 8
      height          = 8
      search_filter = {
        ec2_tag = [
          { tag_name = "server-type", tag_value = "RDGateway" },
        ]
      }
      widgets = [
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-in-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-out-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_windows.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_windows.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_windows.high-memory-usage,
      ]
    }

    rdservices = {
      header_markdown = "## EC2 RDServices Tier"
      width           = 8
      height          = 8
      search_filter = {
        ec2_tag = [
          { tag_name = "server-type", tag_value = "RDServices" },
        ]
      }
      widgets = [
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-in-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-out-bandwidth,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_windows.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_windows.free-disk-space-low,
        module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_windows.high-memory-usage,
      ]
    }
  }
}

