# Widgets generally correspond to equivalent cloudwatch_metric_alarm
# SELECT expressions only allow last 3 hours data, so SEARCH is used instead
# x,y,width,height are not defined here - the cloudwatch_dashboard module populates these
# AccountIds also not defined here - the cloudwatch_dashboard module can add
# AccountIds can be defined per widget like this:
#   SORT(SEARCH('{AWS/EC2,InstanceId} MetricName="CPUUtilization" :aws.AccountId= "272983201692"','Maximum'),MAX,DESC)

locals {

  cloudwatch_dashboards_filter = flatten([
    var.options.cloudwatch_dashboard_default_widget_groups != null ? ["CloudWatch-Default"] : []
  ])

  cloudwatch_dashboard_widgets = {
    ec2 = {
      cpu-utilization-high = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 cpu-utilization-high"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{AWS/EC2,InstanceId} MetricName=\"CPUUtilization\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = local.cloudwatch_metric_alarms.ec2.cpu-utilization-high.threshold
          #    fill  = "above"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "%"
            }
          }
        }
      }
      instance-status-check-failed = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 instance-status-check-failed"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{AWS/EC2,InstanceId} MetricName=\"StatusCheckFailed_Instance\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = 1
          #    fill  = "above"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "exitcode"
            }
          }
        }
      }
      system-status-check-failed = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 system-status-check-failed"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{AWS/EC2,InstanceId} MetricName=\"StatusCheckFailed_System\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = 1
          #    fill  = "above"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "exitcode"
            }
          }
        }
      }
    }

    ec2_cwagent_windows = {
      free-disk-space-low = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 Windows free-disk-space-low"
          stat    = "Minimum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{CWAgent,InstanceId} MetricName=\"DISK_FREE\"','Minimum'),MIN,ASC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = local.cloudwatch_metric_alarms.ec2_cwagent_windows.free-disk-space-low.threshold
          #    fill  = "below"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "disk free %"
            }
          }
        }
      }
      high-memory-usage = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 Windows high-memory-usage"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{CWAgent,InstanceId} MetricName=\"Memory % Committed Bytes In Use\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = local.cloudwatch_metric_alarms.ec2_cwagent_windows.high-memory-usage.threshold
          #    fill  = "above"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "%"
            }
          }
        }
      }
    }

    ec2_cwagent_linux = {
      free-disk-space-low = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 Linux free-disk-space-low"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{CWAgent,InstanceId} MetricName=\"disk_used_percent\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = local.cloudwatch_metric_alarms.ec2_cwagent_linux.free-disk-space-low.threshold
          #    fill  = "above"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "disk used %"
            }
          }
        }
      }
      high-memory-usage = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 Linux high-memory-usage"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{CWAgent,InstanceId} MetricName=\"mem_used_percent\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = local.cloudwatch_metric_alarms.ec2_cwagent_linux.high-memory-usage.threshold
          #    fill  = "above"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "%"
            }
          }
        }
      }
      cpu-iowait-high = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 Linux cpu-iowait-high"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{CWAgent,InstanceId} MetricName=\"cpu_usage_iowait\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = local.cloudwatch_metric_alarms.ec2_cwagent_linux.cpu-iowait-high.threshold
          #    fill  = "above"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "%"
            }
          }
        }
      }
    }
    ec2_instance_cwagent_linux = {
      free-disk-space-low = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 Instance Linux free-disk-space-low"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{CWAgent,InstanceId,device,fstype,name,path,server_type} MetricName=\"disk_used_percent\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = local.cloudwatch_metric_alarms.ec2_cwagent_linux.free-disk-space-low.threshold
          #    fill  = "above"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "disk used %"
            }
          }
        }
      }
    }
    ec2_autoscaling_group_cwagent_linux = {
      free-disk-space-low = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 Autoscaling Group free-disk-space-low"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{CWAgent,AutoScalingGroupName,InstanceId,device,fstype,name,path,server_type} MetricName=\"disk_used_percent\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = local.cloudwatch_metric_alarms.ec2_cwagent_linux.free-disk-space-low.threshold
          #    fill  = "above"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "disk used %"
            }
          }
        }
      }
    }

    ec2_instance_cwagent_collectd_service_status_os = {
      service-status-error-os-layer = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 Instance service-status-error-os-layer"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_service_status_os_value\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = 1
          #    fill  = "above"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "exitcode"
            }
          }
        }
      }
    }
    ec2_autoscaling_group_cwagent_collectd_service_status_os = {
      service-status-error-os-layer = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 Autoscaling Group service-status-error-os-layer"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{CWAgent,AutoScalingGroupName,InstanceId,type,type_instance} MetricName=\"collectd_service_status_os_value\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = 1
          #    fill  = "above"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "exitcode"
            }
          }
        }
      }
    }
    ec2_instance_cwagent_collectd_service_status_app = {
      service-status-error-app-layer = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 Instance service-status-error-app-layer"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_service_status_app_value\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = 1
          #    fill  = "above"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "exitcode"
            }
          }
        }
      }
    }
    ec2_autoscaling_group_cwagent_collectd_service_status_app = {
      service-status-error-app-layer = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 Autoscaling Group service-status-error-app-layer"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{CWAgent,AutoScalingGroupName,InstanceId,type,type_instance} MetricName=\"collectd_service_status_app_value\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = 1
          #    fill  = "above"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "exitcode"
            }
          }
        }
      }
    }
    ec2_instance_cwagent_collectd_connectivity_test = {
      connectivity-test-all-failed = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 Instance connectivity-test-all-failed"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_connectivity_test_value\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = 1
          #    fill  = "above"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "exitcode"
            }
          }
        }
      }
    }
    ec2_instance_cwagent_collectd_textfile_monitoring = {
      textfile-monitoring-metric-error = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 Instance textfile-monitoring-metric-error"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_textfile_monitoring_value\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = 1
          #    fill  = "above"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "exitcode"
            }
          }
        }
      }
      textfile-monitoring-metric-not-updated = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 Instance textfile-monitoring-metric-not-updated"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_textfile_monitoring_seconds\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = local.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_textfile_monitoring.textfile-monitoring-metric-not-updated.threshold
          #    fill  = "above"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "seconds"
            }
          }
        }
      }
    }

    ec2_instance_cwagent_collectd_oracle_db_connected = {
      oracle-db-disconnected = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 oracle-db-disconnected"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_oracle_db_connected_value\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = 1
          #    fill  = "above"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "exitcode"
            }
          }
        }
      }
    }
    ec2_instance_cwagent_collectd_oracle_db_backup = {
      oracle-db-rman-backup-error = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 oracle-db-rman-backup-error"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_textfile_monitoring_rman_backup_value\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = 1
          #    fill  = "above"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "exitcode"
            }
          }
        }
      }
      oracle-db-rman-backup-did-not-run = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 oracle-db-rman-backup-did-not-run"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_textfile_monitoring_rman_backup_seconds\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = local.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_oracle_db_backup.oracle-db-rman-backup-did-not-run.threshold
          #    fill  = "above"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "seconds"
            }
          }
        }
      }
    }
    ec2_instance_cwagent_collectd_filesystems_check = {
      filesystems-check-error = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 Instance filesystems-check-error"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_textfile_monitoring_filesystems_check_value\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = 1
          #    fill  = "above"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "exitcode"
            }
          }
        }
      }
      filesystems-check-metric-not-updated = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 Instance filesystems-check-metric-not-updated"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_textfile_monitoring_filesystems_check_seconds\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = local.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_textfile_monitoring.textfile-monitoring-metric-not-updated.threshold
          #    fill  = "above"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "seconds"
            }
          }
        }
      }
    }

    lb = {
      load-balancer-requests = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "ALB load-balancer-requests"
          stat    = "Sum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"RequestCount\"','Sum'),SUM,DESC)", "label" : "", "id" : "q1" }],
          ]
          yAxis = {
            left = {
              showUnits = false,
              label     = "request count"
            }
          }
        }
      }
      load-balancer-http-4XXs = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "ALB load-balancer-http-4XXs"
          stat    = "Sum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"HTTPCode_ELB_4XX_Count\"','Sum'),SUM,DESC)", "label" : "", "id" : "q1" }],
          ]
          yAxis = {
            left = {
              showUnits = false,
              label     = "error count"
            }
          }
        }
      }
      load-balancer-http-5XXs = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "ALB load-balancer-http-5XXs"
          stat    = "Sum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"HTTPCode_ELB_5XX_Count\"','Sum'),SUM,DESC)", "label" : "", "id" : "q1" }],
          ]
          yAxis = {
            left = {
              showUnits = false,
              label     = "error count"
            }
          }
        }
      }
      load-balancer-target-group-requests = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "ALB load-balancer-target-group-requests"
          stat    = "Sum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"RequestCount\"','Sum'),SUM,DESC)", "label" : "", "id" : "q1" }],
          ]
          yAxis = {
            left = {
              showUnits = false,
              label     = "request count"
            }
          }
        }
      }
      load-balancer-target-group-http-4XXs = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "ALB load-balancer-target-group-http-4XXs"
          stat    = "Sum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"HTTPCode_Target_4XX_Count\"','Sum'),SUM,DESC)", "label" : "", "id" : "q1" }],
          ]
          yAxis = {
            left = {
              showUnits = false,
              label     = "error count"
            }
          }
        }
      }
      load-balancer-target-group-http-5XXs = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "ALB load-balancer-target-group-http-5XXs"
          stat    = "Sum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"HTTPCode_Target_5XX_Count\"','Sum'),SUM,DESC)", "label" : "", "id" : "q1" }],
          ]
          yAxis = {
            left = {
              showUnits = false,
              label     = "error count"
            }
          }
        }
      }
      load-balancer-active-connections = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "ALB load-balancer-active-connections"
          stat    = "Average"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"ActiveConnectionCount\"','Average'),AVG,DESC)", "label" : "", "id" : "q1" }],
          ]
          yAxis = {
            left = {
              showUnits = false,
              label     = "connection count"
            }
          }
        }
      }
      load-balancer-new-connections = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "ALB load-balancer-new-connections"
          stat    = "Sum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"NewConnectionCount\"','Sum'),SUM,DESC)", "label" : "", "id" : "q1" }],
          ]
          yAxis = {
            left = {
              showUnits = false,
              label     = "connection count"
            }
          }
        }
      }
      load-balancer-target-connection-errors = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "ALB load-balancer-target-connection-errors"
          stat    = "Sum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"TargetConnectionErrorCount\"','Sum'),SUM,DESC)", "label" : "", "id" : "q1" }],
          ]
          yAxis = {
            left = {
              showUnits = false,
              label     = "connection errors"
            }
          }
        }
      }
      unhealthy-load-balancer-host = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "ALB unhealthy-load-balancer-host"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"UnHealthyHostCount\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = local.cloudwatch_metric_alarms.lb.unhealthy-load-balancer-host.threshold
          #    fill  = "above"
          #  }]
          #}
          yAxis = {
            left = {
              showUnits = false,
              label     = "host count"
            }
          }
        }
      }
      load-balancer-target-response-time = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "load-balancer-target-response-time"
          stat    = "Average"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"TargetResponseTime\"','Average'),AVG,DESC)", "label" : "", "id" : "q1" }],
          ]
          yAxis = {
            left = {
              showUnits = false,
              label     = "seconds"
            }
          }
        }
      }
    }

    network_lb = {
      load-balancer-unhealthy-host-count = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "NLB unhealthy-host-count"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{AWS/NetworkELB,LoadBalancer,TargetGroup} MetricName=\"UnHealthyHostCount\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          yAxis = {
            left = {
              showUnits = false,
              label     = "unhealthy host count"
            }
          }
        }
      }
      load-balancer-active-flow-count = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "NLB active-flow-count"
          stat    = "Average"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{AWS/NetworkELB,LoadBalancer,LoadBalancer} MetricName=\"ActiveFlowCount\"','Average'),AVG,DESC)", "label" : "", "id" : "q1" }],
          ]
          yAxis = {
            left = {
              showUnits = false,
              label     = "active flow count"
            }
          }
        }
      }
      load-balancer-new-flow-count = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "NLB new-flow-count"
          stat    = "Sum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{AWS/NetworkELB,LoadBalancer,LoadBalancer} MetricName=\"NewFlowCount\"','Sum'),SUM,DESC)", "label" : "", "id" : "q1" }],
          ]
          yAxis = {
            left = {
              showUnits = false,
              label     = "new flow count"
            }
          }
        }
      }
      load-balancer-peak-packets-per-second = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "NLB peak-packets-per-second"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{AWS/NetworkELB,LoadBalancer,LoadBalancer} MetricName=\"PeakPacketsPerSecond\"','Maximum'),MAX,DESC)", "label" : "", "id" : "q1" }],
          ]
          yAxis = {
            left = {
              showUnits = false,
              label     = "peak packets per second"
            }
          }
        }
      }
      load-balancer-processed-bytes = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "NLB processed-bytes"
          stat    = "Sum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{AWS/NetworkELB,LoadBalancer,LoadBalancer} MetricName=\"ProcessedBytes\"','Sum'),SUM,DESC)", "label" : "", "id" : "q1" }],
          ]
          yAxis = {
            left = {
              showUnits = false,
              label     = "processed bytes"
            }
          }
        }
      }
      load-balancer-processed-packets = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "NLB processed-packets"
          stat    = "Sum"
          metrics = [
            [{ "expression" : "SORT(SEARCH('{AWS/NetworkELB,LoadBalancer,LoadBalancer} MetricName=\"ProcessedPackets\"','Sum'),SUM,DESC)", "label" : "", "id" : "q1" }],
          ]
          yAxis = {
            left = {
              showUnits = false,
              label     = "processed packets"
            }
          }
        }
      }
    }
    ssm = {
      ssm-command-invocation-status = {
        type = "metric"
        properties = {
          view    = "singleValue"
          stacked = true
          region  = "eu-west-2"
          title   = "SSM CommandInvocation Failures - Per Account"
          stat    = "Maximum"
          period  = 300
          metrics = [
            [{ "expression" : "REMOVE_EMPTY(SEARCH('{CustomMetrics, Account} FailedSSMCommandInvocations', 'Sum', 300))", "label" : "Failed Invocations - ", "id" : "q1" }]
          ]
          yAxis = {
            left = {
              showUnits = false,
              label     = "failed invocations"
            }
          }
        }
      }
    }
    github = {
      github-failed-workflow-runs = {
        type = "metric"
        properties = {
          view    = "singleValue"
          stacked = true
          region  = "eu-west-2"
          title   = "GitHub Failed Workflow Runs - Per Repository"
          stat    = "Maximum"
          period  = 300
          metrics = [
            [{ "expression" : "REMOVE_EMPTY(SEARCH('{CustomMetrics, Repository} FailedGitHubWorkflowRuns', 'Sum', 300))", "label" : "Failed Runs - ", "id" : "q1" }]
          ]
          yAxis = {
            left = {
              showUnits = false,
              label     = "failed runs"
            }
          }
        }
      }
    }
  }

  cloudwatch_dashboard_widget_groups = {
    ec2 = {
      header_markdown = "## EC2 all instances"
      width           = 8
      height          = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
        local.cloudwatch_dashboard_widgets.ec2.instance-status-check-failed,
        local.cloudwatch_dashboard_widgets.ec2.system-status-check-failed,
      ]
    }
    ec2_windows = {
      header_markdown = "## EC2 all Windows instances"
      width           = 8
      height          = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.ec2_cwagent_windows.free-disk-space-low,
        local.cloudwatch_dashboard_widgets.ec2_cwagent_windows.high-memory-usage,
        null
      ]
    }
    ec2_linux = {
      header_markdown = "## EC2 all Linux instances"
      width           = 8
      height          = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.ec2_cwagent_linux.free-disk-space-low,
        local.cloudwatch_dashboard_widgets.ec2_cwagent_linux.high-memory-usage,
        local.cloudwatch_dashboard_widgets.ec2_cwagent_linux.cpu-iowait-high,
      ]
    }
    ec2_autoscaling_group_linux = {
      header_markdown = "## EC2 autoscaling group Linux instances"
      width           = 8
      height          = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.ec2_autoscaling_group_cwagent_linux.free-disk-space-low,
        local.cloudwatch_dashboard_widgets.ec2_autoscaling_group_cwagent_collectd_service_status_os.service-status-error-os-layer,
        local.cloudwatch_dashboard_widgets.ec2_autoscaling_group_cwagent_collectd_service_status_app.service-status-error-app-layer,
      ]
    }
    ec2_instance_linux = {
      header_markdown = "## EC2 standalone Linux instances"
      width           = 8
      height          = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_linux.free-disk-space-low,
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_os.service-status-error-os-layer,
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_app.service-status-error-app-layer,
      ]
    }
    ec2_instance_textfile_monitoring = {
      width  = 8
      height = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_textfile_monitoring.textfile-monitoring-metric-error,
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_textfile_monitoring.textfile-monitoring-metric-not-updated,
        null,
      ]
    }
    ec2_instance_textfile_monitoring_with_connectivity_test = {
      width  = 8
      height = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_textfile_monitoring.textfile-monitoring-metric-error,
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_textfile_monitoring.textfile-monitoring-metric-not-updated,
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_connectivity_test.connectivity-test-all-failed,
      ]
    }
    ec2_instance_oracle_db = {
      width  = 8
      height = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_oracle_db_connected.oracle-db-disconnected,
        null,
        null,
      ]
    }
    ec2_instance_oracle_db_with_backup = {
      width  = 8
      height = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_oracle_db_connected.oracle-db-disconnected,
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_oracle_db_backup.oracle-db-rman-backup-error,
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_oracle_db_backup.oracle-db-rman-backup-did-not-run,
      ]
    }
    ec2_instance_filesystems = {
      width  = 8
      height = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_filesystems_check.filesystems-check-error,
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_filesystems_check.filesystems-check-metric-not-updated,
      ]
    }

    lb = {
      header_markdown = "## Application ELB"
      width           = 8
      height          = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.lb.load-balancer-requests,
        local.cloudwatch_dashboard_widgets.lb.load-balancer-http-4XXs,
        local.cloudwatch_dashboard_widgets.lb.load-balancer-http-5XXs,
        local.cloudwatch_dashboard_widgets.lb.load-balancer-target-group-requests,
        local.cloudwatch_dashboard_widgets.lb.load-balancer-target-group-http-4XXs,
        local.cloudwatch_dashboard_widgets.lb.load-balancer-target-group-http-5XXs,
        local.cloudwatch_dashboard_widgets.lb.load-balancer-active-connections,
        local.cloudwatch_dashboard_widgets.lb.load-balancer-new-connections,
        local.cloudwatch_dashboard_widgets.lb.load-balancer-target-connection-errors,
        local.cloudwatch_dashboard_widgets.lb.unhealthy-load-balancer-host,
        local.cloudwatch_dashboard_widgets.lb.load-balancer-target-response-time,
        null,
      ]
    }
    network_lb = {
      header_markdown = "## Network ELB"
      width           = 8
      height          = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.network_lb.load-balancer-unhealthy-host-count,
        local.cloudwatch_dashboard_widgets.network_lb.load-balancer-active-flow-count,
        local.cloudwatch_dashboard_widgets.network_lb.load-balancer-new-flow-count,
        local.cloudwatch_dashboard_widgets.network_lb.load-balancer-processed-bytes,
        local.cloudwatch_dashboard_widgets.network_lb.load-balancer-processed-packets,
        local.cloudwatch_dashboard_widgets.network_lb.load-balancer-peak-packets-per-second,
      ]
    }
    custom = {
      header_markdown = "## Custom Metrics"
      width           = 8
      height          = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.ssm.ssm-command-invocation-status,
        local.cloudwatch_dashboard_widgets.github.github-failed-workflow-runs,
      ]
    }
  }

  cloudwatch_dashboards = {
    "CloudWatch-Default" = {
      periodOverride = "auto"
      start          = "-PT6H"
      widget_groups = [
        for group in coalesce(var.options.cloudwatch_dashboard_default_widget_groups, []) :
        local.cloudwatch_dashboard_widget_groups[group]
      ]
    }
  }
}
