# Widgets generally correspond to equivalent cloudwatch_metric_alarm
# SELECT expressions only allow last 3 hours data, so SEARCH is used instead
# x,y,width,height are not defined here - the cloudwatch_dashboard module populates these
# AccountIds also not defined here - the cloudwatch_dashboard module can add
# AccountIds can be defined per widget like this (use account ID or "LOCAL")
#   SORT(SEARCH('{AWS/EC2,InstanceId} MetricName="CPUUtilization" :aws.AccountId= "272983201692"','Maximum'),MAX,DESC)

locals {

  cloudwatch_dashboards_filter = flatten([
    var.options.cloudwatch_dashboard_default_widget_groups != null ? ["CloudWatch-Default"] : []
  ])

  cloudwatch_dashboard_widgets = {
    ec2 = {
      cpu-utilization-high = {
        type            = "metric"
        alarm_threshold = local.cloudwatch_metric_alarms.ec2.cpu-utilization-high.threshold
        expression      = "SORT(SEARCH('{AWS/EC2,InstanceId} MetricName=\"CPUUtilization\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 cpu-utilization-high"
          stat    = "Maximum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "%"
            }
          }
        }
      }
      network-in-bandwidth = {
        type              = "metric"
        expression        = "SORT(SEARCH('{AWS/EC2,InstanceId} MetricName=\"NetworkIn\"','Sum')/(125000*300),SUM,DESC)"
        expression_period = 300
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 network-in-5min-average"
          stat    = "Average"
          yAxis = {
            left = {
              showUnits = false,
              label     = "Mbps"
            }
          }
        }
      }
      network-out-bandwidth = {
        type              = "metric"
        expression        = "SORT(SEARCH('{AWS/EC2,InstanceId} MetricName=\"NetworkOut\"','Sum')/(125000*300),SUM,DESC)"
        expression_period = 300
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 network-out-5min-average"
          stat    = "Average"
          yAxis = {
            left = {
              showUnits = false,
              label     = "Mbps"
            }
          }
        }
      }
      instance-status-check-failed = {
        type            = "metric"
        alarm_threshold = 1
        expression      = "SORT(SEARCH('{AWS/EC2,InstanceId} MetricName=\"StatusCheckFailed_Instance\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 instance-status-check-failed"
          stat    = "Maximum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "exitcode"
            }
          }
        }
      }
      system-status-check-failed = {
        type            = "metric"
        alarm_threshold = 1
        expression      = "SORT(SEARCH('{AWS/EC2,InstanceId} MetricName=\"StatusCheckFailed_System\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 system-status-check-failed"
          stat    = "Maximum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "exitcode"
            }
          }
        }
      }
      attached-ebs-status-check-failed = {
        type            = "metric"
        alarm_threshold = 1
        expression      = "SORT(SEARCH('{AWS/EC2,InstanceId} MetricName=\"StatusCheckFailed_AttachedEBS\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 attached-ebs-status-check-failed"
          stat    = "Maximum"
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
        type            = "metric"
        alarm_threshold = local.cloudwatch_metric_alarms.ec2_cwagent_windows.free-disk-space-low.threshold
        expression      = "SORT(SEARCH('{CWAgent,InstanceId} MetricName=\"DISK_FREE\"','Minimum'),MIN,ASC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 Windows free-disk-space-low"
          stat    = "Minimum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "disk free %"
            }
          }
        }
      }
      high-memory-usage = {
        type            = "metric"
        alarm_threshold = local.cloudwatch_metric_alarms.ec2_cwagent_windows.high-memory-usage.threshold
        expression      = "SORT(SEARCH('{CWAgent,InstanceId} MetricName=\"Memory % Committed Bytes In Use\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 Windows high-memory-usage"
          stat    = "Maximum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "%"
            }
          }
        }
      }
    }
    ec2_instance_cwagent_windows = {
      free-disk-space-low = {
        type            = "metric"
        alarm_threshold = local.cloudwatch_metric_alarms.ec2_cwagent_windows.free-disk-space-low.threshold
        expression      = "SORT(SEARCH('{CWAgent,InstanceId,instance,objectname} MetricName=\"DISK_FREE\"','Minimum'),MIN,ASC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 Instance Windows free-disk-space-low"
          stat    = "Minimum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "disk free %"
            }
          }
        }
      }
    }
    ec2_autoscaling_group_cwagent_windows = {
      free-disk-space-low = {
        type            = "metric"
        alarm_threshold = local.cloudwatch_metric_alarms.ec2_cwagent_windows.free-disk-space-low.threshold
        expression      = "SORT(SEARCH('{CWAgent,AutoScalingGroupName,InstanceId,instance,objectname} MetricName=\"DISK_FREE\"','Minimum'),MIN,ASC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 Autoscaling Group Windows free-disk-space-low"
          stat    = "Minimum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "disk used %"
            }
          }
        }
      }
    }

    ec2_cwagent_linux = {
      free-disk-space-low = {
        type            = "metric"
        alarm_threshold = local.cloudwatch_metric_alarms.ec2_cwagent_linux.free-disk-space-low.threshold
        expression      = "SORT(SEARCH('{CWAgent,InstanceId} MetricName=\"disk_used_percent\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 Linux free-disk-space-low"
          stat    = "Maximum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "disk used %"
            }
          }
        }
      }
      high-memory-usage = {
        type            = "metric"
        alarm_threshold = local.cloudwatch_metric_alarms.ec2_cwagent_linux.high-memory-usage.threshold
        expression      = "SORT(SEARCH('{CWAgent,InstanceId} MetricName=\"mem_used_percent\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 Linux high-memory-usage"
          stat    = "Maximum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "%"
            }
          }
        }
      }
      cpu-iowait-high = {
        type            = "metric"
        alarm_threshold = local.cloudwatch_metric_alarms.ec2_cwagent_linux.cpu-iowait-high.threshold
        expression      = "SORT(SEARCH('{CWAgent,InstanceId} MetricName=\"cpu_usage_iowait\"','Maximum'),AVG,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 Linux cpu-iowait-high"
          stat    = "Average"
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
        type            = "metric"
        alarm_threshold = local.cloudwatch_metric_alarms.ec2_cwagent_linux.free-disk-space-low.threshold
        expression      = "SORT(SEARCH('{CWAgent,InstanceId,device,fstype,name,path,server_type} MetricName=\"disk_used_percent\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 Instance Linux free-disk-space-low"
          stat    = "Maximum"
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
        type            = "metric"
        alarm_threshold = local.cloudwatch_metric_alarms.ec2_cwagent_linux.free-disk-space-low.threshold
        expression      = "SORT(SEARCH('{CWAgent,AutoScalingGroupName,InstanceId,device,fstype,name,path,server_type} MetricName=\"disk_used_percent\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 Autoscaling Group Linux free-disk-space-low"
          stat    = "Maximum"
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
        type            = "metric"
        alarm_threshold = 1
        expression      = "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_service_status_os_value\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 Instance service-status-error-os-layer"
          stat    = "Maximum"
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
        type            = "metric"
        alarm_threshold = 1
        expression      = "SORT(SEARCH('{CWAgent,AutoScalingGroupName,InstanceId,type,type_instance} MetricName=\"collectd_service_status_os_value\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 Autoscaling Group service-status-error-os-layer"
          stat    = "Maximum"
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
        type            = "metric"
        alarm_threshold = 1
        expression      = "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_service_status_app_value\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 Instance service-status-error-app-layer"
          stat    = "Maximum"
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
        type            = "metric"
        alarm_threshold = 1
        expression      = "SORT(SEARCH('{CWAgent,AutoScalingGroupName,InstanceId,type,type_instance} MetricName=\"collectd_service_status_app_value\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 Autoscaling Group service-status-error-app-layer"
          stat    = "Maximum"
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
        type            = "metric"
        alarm_threshold = 1
        expression      = "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_connectivity_test_value\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 Instance connectivity-test-all-failed"
          stat    = "Maximum"
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
        type            = "metric"
        alarm_threshold = 1
        expression      = "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_textfile_monitoring_value\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 Instance textfile-monitoring-metric-error"
          stat    = "Maximum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "exitcode"
            }
          }
        }
      }
      textfile-monitoring-metric-not-updated = {
        type            = "metric"
        alarm_threshold = 1
        expression      = "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_textfile_monitoring_seconds\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 Instance textfile-monitoring-metric-not-updated"
          stat    = "Maximum"
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
        type            = "metric"
        alarm_threshold = 1
        expression      = "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_oracle_db_connected_value\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 oracle-db-disconnected"
          stat    = "Maximum"
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
        type            = "metric"
        alarm_threshold = 1
        expression      = "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_textfile_monitoring_rman_backup_value\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 oracle-db-rman-backup-error"
          stat    = "Maximum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "exitcode"
            }
          }
        }
      }
      oracle-db-rman-backup-did-not-run = {
        type            = "metric"
        alarm_threshold = local.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_oracle_db_backup.oracle-db-rman-backup-did-not-run.threshold
        expression      = "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_textfile_monitoring_rman_backup_seconds\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 oracle-db-rman-backup-did-not-run"
          stat    = "Maximum"
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
        type            = "metric"
        alarm_threshold = 1
        expression      = "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_textfile_monitoring_filesystems_check_value\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 Instance filesystems-check-error"
          stat    = "Maximum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "exitcode"
            }
          }
        }
      }
      filesystems-check-metric-not-updated = {
        type            = "metric"
        alarm_threshold = local.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_textfile_monitoring.textfile-monitoring-metric-not-updated.threshold
        expression      = "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_textfile_monitoring_filesystems_check_seconds\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 Instance filesystems-check-metric-not-updated"
          stat    = "Maximum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "seconds"
            }
          }
        }
      }
    }

    ec2_instance_cwagent_collectd_endpoint_monitoring = {
      endpoint-status = {
        type            = "metric"
        alarm_threshold = 1
        expression      = "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_endpoint_status_value\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "endpoint-status"
          stat    = "Maximum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "exitcode"
            }
          }
        }
      }
      endpoint-response-time-ms = {
        type       = "metric"
        expression = "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_endpoint_response_time_ms_value\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "endpoint-response-time-ms"
          stat    = "Maximum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "ms"
            }
          }
        }
      }
      endpoint-cert-days-to-expiry = {
        type            = "metric"
        alarm_threshold = local.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_endpoint_monitoring.endpoint-cert-expires-soon.threshold
        expression      = "SORT(SEARCH('{CWAgent,InstanceId,type,type_instance} MetricName=\"collectd_endpoint_cert_expiry_value\"','Minimum'),MIN,ASC)"
        properties = {
          view    = "bar"
          period  = 3600
          stacked = false
          region  = "eu-west-2"
          title   = "endpoint-cert-days-to-expiry"
          stat    = "Minimum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "days"
            }
          }
        }
      }
    }

    lb = {
      load-balancer-requests = {
        type       = "metric"
        expression = "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"RequestCount\"','Sum'),SUM,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "ALB load-balancer-requests"
          stat    = "Sum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "request count"
            }
          }
        }
      }
      load-balancer-http-4XXs = {
        type       = "metric"
        expression = "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"HTTPCode_ELB_4XX_Count\"','Sum'),SUM,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "ALB load-balancer-http-4XXs"
          stat    = "Sum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "error count"
            }
          }
        }
      }
      load-balancer-http-5XXs = {
        type       = "metric"
        expression = "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"HTTPCode_ELB_5XX_Count\"','Sum'),SUM,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "ALB load-balancer-http-5XXs"
          stat    = "Sum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "error count"
            }
          }
        }
      }
      load-balancer-target-group-requests = {
        type       = "metric"
        expression = "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"RequestCount\"','Sum'),SUM,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "ALB load-balancer-target-group-requests"
          stat    = "Sum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "request count"
            }
          }
        }
      }
      load-balancer-target-group-http-4XXs = {
        type       = "metric"
        expression = "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"HTTPCode_Target_4XX_Count\"','Sum'),SUM,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "ALB load-balancer-target-group-http-4XXs"
          stat    = "Sum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "error count"
            }
          }
        }
      }
      load-balancer-target-group-http-5XXs = {
        type       = "metric"
        expression = "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"HTTPCode_Target_5XX_Count\"','Sum'),SUM,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "ALB load-balancer-target-group-http-5XXs"
          stat    = "Sum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "error count"
            }
          }
        }
      }
      load-balancer-active-connections = {
        type       = "metric"
        expression = "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"ActiveConnectionCount\"','Average'),AVG,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "ALB load-balancer-active-connections"
          stat    = "Average"
          yAxis = {
            left = {
              showUnits = false,
              label     = "connection count"
            }
          }
        }
      }
      load-balancer-new-connections = {
        type       = "metric"
        expression = "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"NewConnectionCount\"','Sum'),SUM,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "ALB load-balancer-new-connections"
          stat    = "Sum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "connection count"
            }
          }
        }
      }
      load-balancer-target-connection-errors = {
        type       = "metric"
        expression = "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"TargetConnectionErrorCount\"','Sum'),SUM,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "ALB load-balancer-target-connection-errors"
          stat    = "Sum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "connection errors"
            }
          }
        }
      }
      load-balancer-processed-bandwidth = {
        type              = "metric"
        expression        = "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"ProcessedBytes\"','Sum')/(125000*300),SUM,DESC)"
        expression_period = 300
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "ALB processed-data-5min-average"
          stat    = "Average"
          yAxis = {
            left = {
              showUnits = false,
              label     = "Mbps"
            }
          }
        }
      }
      unhealthy-load-balancer-host = {
        type            = "metric"
        expression      = "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"UnHealthyHostCount\"','Maximum'),MAX,DESC)"
        alarm_threshold = local.cloudwatch_metric_alarms.lb.unhealthy-load-balancer-host.threshold
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "ALB unhealthy-load-balancer-host"
          stat    = "Maximum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "host count"
            }
          }
        }
      }
      load-balancer-target-response-time = {
        type       = "metric"
        expression = "SORT(SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"TargetResponseTime\"','Average'),AVG,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "load-balancer-target-response-time"
          stat    = "Average"
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
        type       = "metric"
        expression = "SORT(SEARCH('{AWS/NetworkELB,LoadBalancer,TargetGroup} MetricName=\"UnHealthyHostCount\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "NLB unhealthy-host-count"
          stat    = "Maximum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "unhealthy host count"
            }
          }
        }
      }
      load-balancer-active-flow-count = {
        type       = "metric"
        expression = "SORT(SEARCH('{AWS/NetworkELB,LoadBalancer,LoadBalancer} MetricName=\"ActiveFlowCount\"','Average'),AVG,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "NLB active-flow-count"
          stat    = "Average"
          yAxis = {
            left = {
              showUnits = false,
              label     = "active flow count"
            }
          }
        }
      }
      load-balancer-new-flow-count = {
        type       = "metric"
        expression = "SORT(SEARCH('{AWS/NetworkELB,LoadBalancer,LoadBalancer} MetricName=\"NewFlowCount\"','Sum'),SUM,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "NLB new-flow-count"
          stat    = "Sum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "new flow count"
            }
          }
        }
      }
      load-balancer-peak-packets-per-second = {
        type       = "metric"
        expression = "SORT(SEARCH('{AWS/NetworkELB,LoadBalancer,LoadBalancer} MetricName=\"PeakPacketsPerSecond\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "NLB peak-packets-per-second"
          stat    = "Maximum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "peak packets per second"
            }
          }
        }
      }
      load-balancer-processed-bandwidth = {
        type              = "metric"
        expression        = "SORT(SEARCH('{AWS/NetworkELB,LoadBalancer,LoadBalancer} MetricName=\"ProcessedBytes\"','Sum')/(125000*300),SUM,DESC)"
        expression_period = 300
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "NLB processed-data-5min-average"
          stat    = "Average"
          yAxis = {
            left = {
              showUnits = false,
              label     = "Mbps"
            }
          }
        }
      }
      load-balancer-processed-packets = {
        type       = "metric"
        expression = "SORT(SEARCH('{AWS/NetworkELB,LoadBalancer,LoadBalancer} MetricName=\"ProcessedPackets\"','Sum'),SUM,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "NLB processed-packets"
          stat    = "Sum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "processed packets"
            }
          }
        }
      }
      load-balancer-port-allocation-error-count = {
        type       = "metric"
        expression = "SORT(SEARCH('{AWS/NetworkELB,LoadBalancer,LoadBalancer} MetricName=\"PortAllocationErrorCount\"','Sum'),SUM,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "NLB port-allocation-error-count"
          stat    = "Sum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "error count"
            }
          }
        }
      }
      load-balancer-rejected-flow-count = {
        type       = "metric"
        expression = "SORT(SEARCH('{AWS/NetworkELB,LoadBalancer,LoadBalancer} MetricName=\"RejectedFlowCount\"','Sum'),SUM,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "NLB rejected-flow-count"
          stat    = "Sum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "flow count"
            }
          }
        }
      }
      load-balancer-tcp-client-reset-count = {
        type       = "metric"
        expression = "SORT(SEARCH('{AWS/NetworkELB,LoadBalancer,LoadBalancer} MetricName=\"TCP_Client_Reset_Count\"','Sum'),SUM,DESC)"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "NLB tcp-client-reset-count"
          stat    = "Sum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "reset count"
            }
          }
        }
      }
    }
    ssm = {
      ssm-command-success-count = {
        type       = "metric"
        expression = "SORT(SEARCH('{CustomMetrics, DocumentName} MetricName=\"SSMCommandSuccessCount\"','Sum'),SUM,DESC)"
        properties = {
          view    = "timeSeries"
          period  = 3600
          stacked = true
          region  = "eu-west-2"
          title   = "SSM command-success-count"
          stat    = "Sum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "count"
            }
          }
        }
      }
      ssm-command-failed-count = {
        type       = "metric"
        expression = "SORT(SEARCH('{CustomMetrics, DocumentName} MetricName=\"SSMCommandFailedCount\"','Sum'),SUM,DESC)"
        properties = {
          view    = "timeSeries"
          period  = 3600
          stacked = true
          region  = "eu-west-2"
          title   = "SSM command-failed-count"
          stat    = "Sum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "count"
            }
          }
        }
      }
      ssm-command-ignore-count = {
        type       = "metric"
        expression = "SORT(SEARCH('{CustomMetrics, DocumentName} MetricName=\"SSMCommandIgnoreCount\"','Sum'),SUM,DESC)"
        properties = {
          view    = "timeSeries"
          period  = 3600
          stacked = true
          region  = "eu-west-2"
          title   = "SSM command-ignore-count"
          stat    = "Sum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "count"
            }
          }
        }
      }
    }
    github = {
      github-actions-run-success-count-by-repo = {
        type       = "metric"
        expression = "SORT(SEARCH('{CustomMetrics, Repo} MetricName=\"GitHubActionRunsSuccessCount\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          period  = 1800
          stacked = true
          region  = "eu-west-2"
          title   = "GitHub actions-run-success-count-by-repo"
          stat    = "Maximum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "count"
            }
          }
        }
      }
      github-actions-run-failed-count-by-repo = {
        type       = "metric"
        expression = "SORT(SEARCH('{CustomMetrics, Repo} MetricName=\"GitHubActionRunsFailedCount\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          period  = 1800
          stacked = true
          region  = "eu-west-2"
          title   = "GitHub actions-run-failed-count-by-repo"
          stat    = "Maximum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "count"
            }
          }
        }
      }
      github-actions-run-failed-count-by-workflow = {
        type       = "metric"
        expression = "SORT(SEARCH('{CustomMetrics, WorkflowName} MetricName=\"GitHubActionRunsFailedCount\"','Maximum'),MAX,DESC)"
        properties = {
          view    = "timeSeries"
          period  = 1800
          stacked = true
          region  = "eu-west-2"
          title   = "GitHub actions-run-failed-count-by-workflow"
          stat    = "Maximum"
          yAxis = {
            left = {
              showUnits = false,
              label     = "count"
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
        local.cloudwatch_dashboard_widgets.ec2.network-in-bandwidth,
        local.cloudwatch_dashboard_widgets.ec2.network-out-bandwidth,
        local.cloudwatch_dashboard_widgets.ec2.instance-status-check-failed,
        local.cloudwatch_dashboard_widgets.ec2.system-status-check-failed,
        local.cloudwatch_dashboard_widgets.ec2.attached-ebs-status-check-failed
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
    ec2_instance_only_windows = {
      header_markdown = "## EC2 all Windows standalone instances"
      width           = 8
      height          = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.ec2_cwagent_windows.free-disk-space-low,
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_windows.free-disk-space-low,
        local.cloudwatch_dashboard_widgets.ec2_cwagent_windows.high-memory-usage,
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
    ec2_instance_endpoint_monitoring = {
      header_markdown = "## Endpoint Monitoring via EC2 collectd"
      width           = 8
      height          = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_endpoint_monitoring.endpoint-status,
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_endpoint_monitoring.endpoint-response-time-ms,
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_endpoint_monitoring.endpoint-cert-days-to-expiry,
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
        local.cloudwatch_dashboard_widgets.lb.load-balancer-processed-bandwidth,
        local.cloudwatch_dashboard_widgets.lb.unhealthy-load-balancer-host,
        local.cloudwatch_dashboard_widgets.lb.load-balancer-target-response-time,
        local.cloudwatch_dashboard_widgets.lb.load-balancer-target-group-requests,
        local.cloudwatch_dashboard_widgets.lb.load-balancer-target-group-http-4XXs,
        local.cloudwatch_dashboard_widgets.lb.load-balancer-target-group-http-5XXs,
        local.cloudwatch_dashboard_widgets.lb.load-balancer-active-connections,
        local.cloudwatch_dashboard_widgets.lb.load-balancer-new-connections,
        local.cloudwatch_dashboard_widgets.lb.load-balancer-target-connection-errors,
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
        local.cloudwatch_dashboard_widgets.network_lb.load-balancer-processed-bandwidth,
        local.cloudwatch_dashboard_widgets.network_lb.load-balancer-processed-packets,
        local.cloudwatch_dashboard_widgets.network_lb.load-balancer-peak-packets-per-second,
        local.cloudwatch_dashboard_widgets.network_lb.load-balancer-port-allocation-error-count,
        local.cloudwatch_dashboard_widgets.network_lb.load-balancer-rejected-flow-count,
        local.cloudwatch_dashboard_widgets.network_lb.load-balancer-tcp-client-reset-count,
      ]
    }
    ssm_command = {
      header_markdown = "## SSM Command Metrics"
      width           = 8
      height          = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.ssm.ssm-command-success-count,
        local.cloudwatch_dashboard_widgets.ssm.ssm-command-failed-count,
        local.cloudwatch_dashboard_widgets.ssm.ssm-command-ignore-count,
      ]
    }
    github_workflows = {
      header_markdown = "## GitHub Workflow Metrics"
      width           = 8
      height          = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.github.github-actions-run-success-count-by-repo,
        local.cloudwatch_dashboard_widgets.github.github-actions-run-failed-count-by-repo,
        local.cloudwatch_dashboard_widgets.github.github-actions-run-failed-count-by-workflow,
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
