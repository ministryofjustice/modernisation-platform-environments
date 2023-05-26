# Create multiple lists of alarms for use in AWS resources
#
# Common alarm definitions are in cloudwatch_metric_alarms. 
# Additional application specific alarms can be passed into
# the module via var.options.cloudwatch_metric_alarms
#
# Some useful defaults are defined below in 
# local.cloudwatch_metric_alarms_lists_baseline.  Use the 
# var.options.cloudwatch_metric_alarms_lists variable to
# create your own lists.  
#
# Note that parent_keys are not recursive, all parents must be 
# specified every time

locals {

  cloudwatch_metric_alarms_lists_merged = merge(
    local.cloudwatch_metric_alarms_lists_baseline,
    var.options.cloudwatch_metric_alarms_lists
  )

  cloudwatch_metric_alarms_lists_parents_expanded = {
    for key, value in local.cloudwatch_metric_alarms_lists_merged : key => flatten([
      [for parent_key in value.parent_keys : local.cloudwatch_metric_alarms_lists_merged[parent_key].alarms_list],
      value.alarms_list
    ])
  }

  # A key error here indicates terraform cannot find one of the alarms
  # in the list, i.e. key/name pair, in the cloudwatch_metric_alarms local
  #
  # A duplicate error means the same alarm name has been referenced twice
  # in the same list
  #
  cloudwatch_metric_alarms_lists = {
    for key, alarms_list in local.cloudwatch_metric_alarms_lists_parents_expanded : key => {
      for item in alarms_list : item.name => local.cloudwatch_metric_alarms[item.key][item.name]
    }
  }

  cloudwatch_metric_alarms_lists_baseline = {

    acm_default = {
      parent_keys = []
      alarms_list = [
        { key = "acm", name = "cert-expires-in-less-than-14-days" },
      ]
    }
    lb_default = {
      parent_keys = []
      alarms_list = [
        { key = "lb", name = "unhealthy-hosts-atleast-one" },
      ]
    }
    ec2_default = {
      parent_keys = []
      alarms_list = [
        { key = "ec2", name = "cpu-utilization-high-15mins" },
        { key = "ec2", name = "instance-status-check-failed-in-last-hour" },
        { key = "ec2", name = "system-status-check-failed-in-last-hour" },
      ]
    }

    ec2_linux_default = {
      parent_keys = ["ec2_default"]
      alarms_list = [
        { key = "ec2_cwagent_linux", name = "free-disk-space-low-1hour" },
        { key = "ec2_cwagent_linux", name = "high-memory-usage-15mins" },
        { key = "ec2_cwagent_linux", name = "cpu-iowait-high-3hour" },
      ]
    }
    ec2_linux_with_collectd_default = {
      parent_keys = ["ec2_default", "ec2_linux_default"]
      alarms_list = [
        { key = "ec2_cwagent_collectd", name = "chronyd-stopped" },
        { key = "ec2_cwagent_collectd", name = "sshd-stopped" },
        { key = "ec2_cwagent_collectd", name = "cloudwatch-agent-stopped" },
        { key = "ec2_cwagent_collectd", name = "ssm-agent-stopped" },
      ]
    }
    ec2_windows_default = {
      parent_keys = ["ec2_default"]
      alarms_list = [
        { key = "ec2_cwagent_windows", name = "free-disk-space-low-1hour" },
        { key = "ec2_cwagent_windows", name = "high-memory-usage-15mins" },
      ]
    }
  }
}
