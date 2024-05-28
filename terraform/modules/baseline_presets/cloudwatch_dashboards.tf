locals {

  cloudwatch_dashboards_filter = flatten([
    var.options.cloudwatch_dashboard_default_widget_groups != null ? ["CloudWatch-Default"] : []
  ])

  cloudwatch_dashboard_widgets = {
    ec2_expression = {
      cpu-utilization-high = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 cpu-utilization-high"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SELECT MAX(CPUUtilization)\nFROM SCHEMA(\"AWS/EC2\", InstanceId)\nGROUP BY InstanceId\nORDER BY MAX() DESC", "label" : "", "id" : "q1" }],
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
            [{ "expression" : "SELECT MAX(StatusCheckFailed_Instance)\nFROM SCHEMA(\"AWS/EC2\", InstanceId)\nGROUP BY InstanceId\nORDER BY MAX() DESC", "label" : "", "id" : "q1" }],
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
            [{ "expression" : "SELECT MAX(StatusCheckFailed_System)\nFROM SCHEMA(\"AWS/EC2\", InstanceId)\nGROUP BY InstanceId\nORDER BY MAX() DESC\nLIMIT 20", "label" : "", "id" : "q1" }],
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

    ec2_cwagent_windows_expression = {
      free-disk-space-low = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 Windows free-disk-space-low"
          stat    = "Minimum"
          metrics = [
            [{ "expression" : "SELECT MIN(DISK_FREE) FROM SCHEMA(CWAgent, InstanceId) GROUP BY InstanceId ORDER BY MIN() ASC", "label" : "", "id" : "q1", "yAxis" : "left" }],
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
            [{ "expression" : "SELECT MAX(Memory % Committed Bytes In Use) FROM SCHEMA(CWAgent, InstanceId) GROUP BY InstanceId ORDER BY MAX() DESC", "label" : "", "id" : "q1", "yAxis" : "left" }],
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

    ec2_cwagent_linux_expression = {
      free-disk-space-low = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 Linux free-disk-space-low"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SELECT MAX(disk_used_percent) FROM SCHEMA(CWAgent, InstanceId, device, fstype, name, path, server_type) GROUP BY InstanceId, path ORDER BY MAX() DESC", "label" : "", "id" : "q1" }],
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
            [{ "expression" : "SELECT MAX(mem_used_percent) FROM SCHEMA(CWAgent, InstanceId) GROUP BY InstanceId ORDER BY MAX() DESC", "label" : "", "id" : "q1", "yAxis" : "left" }],
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
            [{ "expression" : "SELECT MAX(cpu_usage_iowait) FROM SCHEMA(CWAgent, InstanceId) GROUP BY InstanceId ORDER BY MAX() DESC", "label" : "", "id" : "q1" }],
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

    ec2_instance_cwagent_collectd_service_status_os_expression = {
      service-status-error-os-layer = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 service-status-error-os-layer"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SELECT MAX(collectd_service_status_os_value) FROM SCHEMA(CWAgent, InstanceId, type, type_instance) GROUP BY InstanceId, type, type_instance ORDER BY MAX() DESC", "label" : "", "id" : "q1", "yAxis" : "left" }],
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
    ec2_instance_cwagent_collectd_service_status_app_expression = {
      service-status-error-app-layer = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 service-status-error-app-layer"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SELECT MAX(collectd_service_status_app_value) FROM SCHEMA(CWAgent, InstanceId, type, type_instance) GROUP BY InstanceId, type, type_instance ORDER BY MAX() DESC", "label" : "", "id" : "q1", "yAxis" : "left" }],
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
    ec2_instance_cwagent_collectd_connectivity_test_expression = {
      connectivity-test-all-failed = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 connectivity-test-all-failed"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SELECT MAX(collectd_connectivity_test_value) FROM SCHEMA(CWAgent, InstanceId, type, type_instance) GROUP BY InstanceId, type, type_instance ORDER BY MAX() DESC", "label" : "", "id" : "q1", "yAxis" : "left" }],
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
    ec2_instance_cwagent_collectd_textfile_monitoring_expression = {
      textfile-monitoring-metric-error = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 textfile-monitoring-metric-error"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SELECT MAX(collectd_textfile_monitoring_value) FROM SCHEMA(CWAgent, InstanceId, type, type_instance) GROUP BY InstanceId, type, type_instance ORDER BY MAX() DESC", "label" : "", "id" : "q1", "yAxis" : "left" }],
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
          title   = "EC2 textfile-monitoring-metric-not-updated"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SELECT MAX(collectd_textfile_monitoring_seconds) FROM SCHEMA(CWAgent, InstanceId, type, type_instance) GROUP BY InstanceId, type, type_instance ORDER BY MAX() DESC", "label" : "", "id" : "q1", "yAxis" : "left" }],
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

    ec2_instance_cwagent_collectd_oracle_db_connected_expression = {
      oracle-db-disconnected = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 oracle-db-disconnected"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SELECT MAX(collectd_oracle_db_connected_value) FROM SCHEMA(CWAgent, InstanceId, type, type_instance) GROUP BY InstanceId, type, type_instance ORDER BY MAX() DESC", "label" : "", "id" : "q1", "yAxis" : "left" }],
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
    ec2_instance_cwagent_collectd_oracle_db_backup_expression = {
      oracle-db-rman-backup-error = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "EC2 oracle-db-rman-backup-error"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SELECT MAX(collectd_textfile_monitoring_rman_backup_value) FROM SCHEMA(CWAgent, InstanceId, type, type_instance) GROUP BY InstanceId, type, type_instance ORDER BY MAX() DESC", "label" : "", "id" : "q1", "yAxis" : "left" }],
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
            [{ "expression" : "SELECT MAX(collectd_textfile_monitoring_rman_backup_seconds) FROM SCHEMA(CWAgent, InstanceId, type, type_instance) GROUP BY InstanceId, type, type_instance ORDER BY MAX() DESC", "label" : "", "id" : "q1", "yAxis" : "left" }],
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

    lb_expression = {
      load-balancer-requests = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "ALB load-balancer-requests"
          stat    = "Sum"
          metrics = [
            [{ "expression" : "SELECT SUM(RequestCount) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer) GROUP BY LoadBalancer ORDER BY SUM() DESC", "label" : "", "id" : "q1" }],
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
            [{ "expression" : "SELECT SUM(HTTPCode_ELB_4XX_Count) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer) GROUP BY LoadBalancer ORDER BY SUM() DESC", "label" : "", "id" : "q1" }],
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
            [{ "expression" : "SELECT SUM(HTTPCode_ELB_5XX_Count) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer) GROUP BY LoadBalancer ORDER BY SUM() DESC", "label" : "", "id" : "q1" }],
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
          title   = "ALB load-balancer-requests"
          stat    = "Sum"
          metrics = [
            [{ "expression" : "SELECT SUM(RequestCount) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer, TargetGroup) GROUP BY LoadBalancer, TargetGroup ORDER BY SUM() DESC", "label" : "", "id" : "q2" }],
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
          title   = "ALB load-balancer-http-4XXs"
          stat    = "Sum"
          metrics = [
            [{ "expression" : "SELECT SUM(HTTPCode_Target_4XX_Count) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer, TargetGroup) GROUP BY LoadBalancer, TargetGroup ORDER BY SUM() DESC", "label" : "", "id" : "q2" }],
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
          title   = "ALB load-balancer-http-5XXs"
          stat    = "Sum"
          metrics = [
            [{ "expression" : "SELECT SUM(HTTPCode_Target_5XX_Count) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer, TargetGroup) GROUP BY LoadBalancer, TargetGroup ORDER BY SUM() DESC", "label" : "", "id" : "q2" }],
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
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SELECT MAX(ActiveConnectionCount) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer) GROUP BY LoadBalancer ORDER BY MAX() DESC", "label" : "", "id" : "q1" }],
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
            [{ "expression" : "SELECT SUM(NewConnectionCount) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer) GROUP BY LoadBalancer ORDER BY SUM() DESC", "label" : "", "id" : "q1" }],
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
            [{ "expression" : "SELECT SUM(TargetConnectionErrorCount) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer) GROUP BY LoadBalancer ORDER BY SUM() DESC", "label" : "", "id" : "q1" }],
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
            [{ "expression" : "SELECT MAX(UnHealthyHostCount) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer, TargetGroup) GROUP BY LoadBalancer, TargetGroup ORDER BY MAX() DESC", "label" : "", "id" : "q1" }],
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
            [{ "expression" : "SELECT AVG(TargetResponseTime) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer, TargetGroup) GROUP BY LoadBalancer, TargetGroup ORDER BY AVG() DESC", "label" : "", "id" : "q1" }],
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

    network_lb_expression = {
      unhealthy-network-load-balancer-host = {
        type = "metric"
        properties = {
          view    = "timeSeries"
          stacked = true
          region  = "eu-west-2"
          title   = "NLB unhealthy-network-load-balancer-host"
          stat    = "Maximum"
          metrics = [
            [{ "expression" : "SELECT MAX(UnHealthyHostCount) FROM SCHEMA(\"AWS/NetworkELB\", LoadBalancer, TargetGroup) GROUP BY LoadBalancer, TargetGroup ORDER BY MAX() DESC", "label" : "", "id" : "q1" }],
          ]
          #annotations = {
          #  horizontal = [{
          #    label = "Alarm Threshold"
          #    value = local.cloudwatch_metric_alarms.network_lb.unhealthy-network-load-balancer-host.threshold
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
    }

  }

  cloudwatch_dashboard_widget_groups = {
    ec2_windows_only_expression = {
      header_markdown = "## EC2"
      width           = 8
      height          = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.ec2_expression.cpu-utilization-high,
        local.cloudwatch_dashboard_widgets.ec2_expression.instance-status-check-failed,
        local.cloudwatch_dashboard_widgets.ec2_expression.system-status-check-failed,
        local.cloudwatch_dashboard_widgets.ec2_cwagent_windows_expression.free-disk-space-low,
        local.cloudwatch_dashboard_widgets.ec2_cwagent_windows_expression.high-memory-usage,
        null,
      ]
    }
    ec2_linux_only_expression = {
      header_markdown = "## EC2"
      width           = 8
      height          = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.ec2_expression.cpu-utilization-high,
        local.cloudwatch_dashboard_widgets.ec2_expression.instance-status-check-failed,
        local.cloudwatch_dashboard_widgets.ec2_expression.system-status-check-failed,
        local.cloudwatch_dashboard_widgets.ec2_cwagent_linux_expression.free-disk-space-low,
        local.cloudwatch_dashboard_widgets.ec2_cwagent_linux_expression.high-memory-usage,
        local.cloudwatch_dashboard_widgets.ec2_cwagent_linux_expression.cpu-iowait-high,
      ]
    }
    ec2_linux_and_windows_expression = {
      header_markdown = "## EC2"
      width           = 8
      height          = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.ec2_expression.cpu-utilization-high,
        local.cloudwatch_dashboard_widgets.ec2_expression.instance-status-check-failed,
        local.cloudwatch_dashboard_widgets.ec2_expression.system-status-check-failed,
        local.cloudwatch_dashboard_widgets.ec2_cwagent_windows_expression.free-disk-space-low,
        local.cloudwatch_dashboard_widgets.ec2_cwagent_windows_expression.high-memory-usage,
        null,
        local.cloudwatch_dashboard_widgets.ec2_cwagent_linux_expression.free-disk-space-low,
        local.cloudwatch_dashboard_widgets.ec2_cwagent_linux_expression.high-memory-usage,
        local.cloudwatch_dashboard_widgets.ec2_cwagent_linux_expression.cpu-iowait-high,
      ]
    }
    ec2_service_status_expression = {
      width  = 8
      height = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_os_expression.service-status-error-os-layer,
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_app_expression.service-status-error-app-layer,
        null,
      ]
    }
    ec2_service_status_with_connectivity_test_expression = {
      width  = 8
      height = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_os_expression.service-status-error-os-layer,
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_service_status_app_expression.service-status-error-app-layer,
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_connectivity_test_expression.connectivity-test-all-failed,
      ]
    }
    ec2_textfile_monitoring_expression = {
      width  = 8
      height = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_textfile_monitoring_expression.textfile-monitoring-metric-error,
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_textfile_monitoring_expression.textfile-monitoring-metric-not-updated,
        null,
      ]
    }
    ec2_oracle_db_expression = {
      width  = 8
      height = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_oracle_db_connected_expression.oracle-db-disconnected,
        null,
        null,
      ]
    }
    ec2_oracle_db_with_backup_expression = {
      width  = 8
      height = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_oracle_db_connected_expression.oracle-db-disconnected,
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_oracle_db_backup_expression.oracle-db-rman-backup-error,
        local.cloudwatch_dashboard_widgets.ec2_instance_cwagent_collectd_oracle_db_backup_expression.oracle-db-rman-backup-did-not-run,
      ]
    }
    lb_expression = {
      header_markdown = "## ALB"
      width           = 8
      height          = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.lb_expression.load-balancer-requests,
        local.cloudwatch_dashboard_widgets.lb_expression.load-balancer-http-4XXs,
        local.cloudwatch_dashboard_widgets.lb_expression.load-balancer-http-5XXs,
        local.cloudwatch_dashboard_widgets.lb_expression.load-balancer-target-group-requests,
        local.cloudwatch_dashboard_widgets.lb_expression.load-balancer-target-group-http-4XXs,
        local.cloudwatch_dashboard_widgets.lb_expression.load-balancer-target-group-http-5XXs,
        local.cloudwatch_dashboard_widgets.lb_expression.load-balancer-active-connections,
        local.cloudwatch_dashboard_widgets.lb_expression.load-balancer-new-connections,
        local.cloudwatch_dashboard_widgets.lb_expression.load-balancer-target-connection-errors,
        local.cloudwatch_dashboard_widgets.lb_expression.unhealthy-load-balancer-host,
        local.cloudwatch_dashboard_widgets.lb_expression.load-balancer-target-response-time,
        null,
      ]
    }
    network_lb_expression = {
      width  = 8
      height = 8
      widgets = [
        local.cloudwatch_dashboard_widgets.network_lb_expression.unhealthy-network-load-balancer-host,
        null,
        null,
      ]
    }
  }

  cloudwatch_dashboards = {
    "CloudWatch-Default" = {
      periodOverride = "auto"
      start          = "-PT3H"
      widget_groups = [
        for group in coalesce(var.options.cloudwatch_dashboard_default_widget_groups, []) :
        local.cloudwatch_dashboard_widget_groups[group]
      ]
    }
  }
}
