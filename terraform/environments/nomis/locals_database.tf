# Use `s3-db-restore-dir` tag to trigger a restore from backup. See
# https://github.com/ministryofjustice/modernisation-platform-configuration-management/blob/main/ansible/roles/db-restore
#
# Use `fixngo-connection-target` tag to monitor connectivity to a target in FixNGo.  See
# https://github.com/ministryofjustice/modernisation-platform-configuration-management/tree/main/ansible/roles/oracle-db-monitoring

locals {

  database_nomis_ssm_parameters = {
    parameters = {
      passwords          = { description = "database passwords" }
      weblogic-passwords = { description = "passwords available to weblogic servers" }
    }
  }
  database_mis_ssm_parameters = {
    parameters = {
      passwords      = { description = "database passwords" }
      misload-config = { description = "misload username, password and hostname" }
    }
  }
  database_ssm_parameters = {
    parameters = {
      passwords = { description = "database passwords" }
    }
  }

  database_cloudwatch_log_metric_filters = {
    rman-backup-status = {
      pattern        = "[month, day, time, hostname, process, message = rman-backup-result, dbname, value]"
      log_group_name = "cwagent-var-log-messages"
      metric_transformation = {
        name      = "RmanBackupStatus"
        namespace = "Database" # custom namespace
        value     = "$value"
        dimensions = {
          dbname = "$dbname"
        }
      }
    }
    misload-status = {
      pattern        = "[month, day, time, hostname, process, message1 = misload-status, dbname, value, message2 = \"last-triggered:\", yearmonthday, utctime]"
      log_group_name = "cwagent-var-log-messages"
      metric_transformation = {
        name      = "MisloadStatus"
        namespace = "Database" # custom namespace
        value     = "$value"
        dimensions = {
          dbname = "$dbname"
        }
      }
    }
  }

  # Alarms created directly by baseline module, i.e. without EC2 dimension
  database_cloudwatch_metric_alarms = {
    rman-backup-failed = {
      comparison_operator = "LessThanOrEqualToThreshold"
      evaluation_periods  = 2
      metric_name         = "RmanBackupStatus"
      namespace           = "Database"
      period              = "3600"
      statistic           = "Maximum"
      threshold           = "0"
      alarm_description   = "Triggers if there has been no successful rman backup"
      alarm_actions       = ["dba_pagerduty"]
      datapoints_to_alarm = 1
      split_by_dimension = {
        dimension_name   = "dbname"
        dimension_values = local.baseline_environment_config.cloudwatch_metric_alarms_dbnames
      }
    }
    misload-failed = {
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 2
      metric_name         = "MisloadStatus"
      namespace           = "Database"
      period              = "3600"
      statistic           = "Maximum"
      threshold           = "1"
      alarm_description   = "Triggers if misload failed"
      alarm_actions       = ["dba_pagerduty"]
      datapoints_to_alarm = 2
      split_by_dimension = {
        dimension_name   = "dbname"
        dimension_values = local.baseline_environment_config.cloudwatch_metric_alarms_dbnames_misload
      }
    }
  }

  # Alarms created directly by ec2-instance module
  # TODO: - change alarm actions to dba_pagerduty once alarms proven out
  database_ec2_cloudwatch_metric_alarms = merge(
    module.baseline_presets.cloudwatch_metric_alarms.ec2,
    module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
    module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd,
    {
      # FIXME: metric name needs changing to collectd_dbconnected_value as part of DSOS-2092, remove dimensions
      oracle-db-disconnected = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "5"
        datapoints_to_alarm = "5"
        metric_name         = "collectd_exec_value"
        namespace           = "CWAgent"
        period              = "60"
        statistic           = "Average"
        threshold           = "1"
        alarm_description   = "Oracle db connection to a particular SID is not working. See: https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4294246698/Oracle+db+connection+alarm for remediation steps."
        alarm_actions       = ["dba_pagerduty"]
        dimensions = {
          instance = "db_connected"
        }
      }
      # FIXME: metric name needs changing to collectd_nomisbatchfailure_value as part of DSOS-2092, remove dimensions
      oracle-batch-failure = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "5"
        datapoints_to_alarm = "5"
        metric_name         = "collectd_exec_value"
        namespace           = "CWAgent"
        period              = "60"
        statistic           = "Average"
        threshold           = "1"
        treat_missing_data  = "notBreaching"
        alarm_description   = "Oracle db has recorded a failed batch status. See: https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4295000327/Batch+Failure for remediation steps."
        alarm_actions       = ["dba_pagerduty"]
        dimensions = {
          instance = "nomis_batch_failure_status"
        }
      }
      # FIXME: metric name needs changing to collectd_nomislongrunningbatch_value as part of DSOS-2092, remove dimensions
      oracle-long-running-batch = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "5"
        datapoints_to_alarm = "5"
        metric_name         = "collectd_exec_value"
        namespace           = "CWAgent"
        period              = "60"
        statistic           = "Average"
        threshold           = "1"
        treat_missing_data  = "notBreaching"
        alarm_description   = "Oracle db has recorded a long-running batch status. See: https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4325966186/Long+Running+Batch for remediation steps."
        alarm_actions       = ["dba_pagerduty"]
        dimensions = {
          instance = "nomis_long_running_batch"
        }
      }
      oracleasm-service = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_oracleasm_value"
        period              = "60"
        statistic           = "Average"
        threshold           = "1"
        alarm_description   = "oracleasm service has stopped"
        alarm_actions       = ["dba_pagerduty"]
      }
      oracle-ohasd-service = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_oracleohasd_value"
        period              = "60"
        statistic           = "Average"
        threshold           = "1"
        alarm_description   = "oracle ohasd service has stopped"
        alarm_actions       = ["dba_pagerduty"]
      }
      cpu-utilization-high = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "120"
        datapoints_to_alarm = "120"
        metric_name         = "CPUUtilization"
        namespace           = "AWS/EC2"
        period              = "60"
        statistic           = "Maximum"
        threshold           = "95"
        alarm_description   = "Triggers if the average cpu remains at 95% utilization or above for 2 hours on a nomis-db instance"
        alarm_actions       = ["dba_pagerduty"]
      }
  })
  database_ec2_cloudwatch_metric_alarms_high_priority = {
    # FIXME: metric name needs changing to collectd_dbconnected_value as part of DSOS-2092, remove dimensions
    oracle-db-disconnected = {
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "5"
      datapoints_to_alarm = "5"
      metric_name         = "collectd_exec_value"
      namespace           = "CWAgent"
      period              = "60"
      statistic           = "Average"
      threshold           = "1"
      alarm_description   = "Oracle db connection to a particular SID is not working. See: https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4294246698/Oracle+db+connection+alarm for remediation steps."
      alarm_actions       = ["dba_high_priority_pagerduty"]
      dimensions = {
        instance = "db_connected"
      }
    }
  }
  # FIXME: metric name needs changing to collectd_fixngoconnected_value as part of DSOS-2093, remove dimensions
  fixngo_connection_cloudwatch_metric_alarms = {
    fixngo-connection = {
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "3"
      namespace           = "CWAgent"
      metric_name         = "collectd_exec_value"
      period              = "60"
      statistic           = "Average"
      threshold           = "1"
      alarm_description   = "this EC2 instance no longer has a connection to the Oracle Enterprise Manager in FixNGo of the connection-target machine"
      alarm_actions       = ["dso_pagerduty"]
      dimensions = {
        instance = "fixngo_connected" # required dimension value for this metric
      }
    }
  }

  database_cloudwatch_log_groups = {
    cwagent-nomis-autologoff = {
      retention_in_days = 90
    }
  }

  database_ec2 = {

    # cloudwatch_metric_alarms = local.database_ec2_cloudwatch_metric_alarms

    config = merge(module.baseline_presets.ec2_instance.config.db, {
      ami_name  = "nomis_rhel_7_9_oracledb_11_2_release_2022-10-07T12-48-08.562Z"
      ami_owner = "self"
    })

    ebs_volumes = {
      "/dev/sdb" = { label = "app" }   # /u01
      "/dev/sdc" = { label = "app" }   # /u02
      "/dev/sde" = { label = "data" }  # DATA01
      "/dev/sdf" = { label = "data" }  # DATA02
      "/dev/sdg" = { label = "data" }  # DATA03
      "/dev/sdh" = { label = "data" }  # DATA04
      "/dev/sdi" = { label = "data" }  # DATA05
      "/dev/sdj" = { label = "flash" } # FLASH01
      "/dev/sdk" = { label = "flash" } # FLASH02
      "/dev/sds" = { label = "swap" }
    }

    ebs_volume_config = {
      data = {
        iops       = 3000
        throughput = 125
      }
      flash = {
        iops       = 3000
        throughput = 125
      }
    }

    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      instance_type                = "r6i.xlarge"
      disable_api_termination      = true
      metadata_options_http_tokens = "optional" # the Oracle installer cannot accommodate a token
      monitoring                   = true
      vpc_security_group_ids       = ["data-db"]
      tags = {
        backup-plan = "daily-and-weekly"
      }
    })

    route53_records = module.baseline_presets.ec2_instance.route53_records.internal_and_external

    ssm_parameters = {
      asm-passwords = {}
    }

    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ansible

    tags = {
      ami                  = "nomis_rhel_7_9_oracledb_11_2"
      backup               = "false" # disable mod platform backup since we use our own policies
      component            = "data"
      server-type          = "nomis-db"
      os-type              = "Linux"
      os-major-version     = 7
      os-version           = "RHEL 7.9"
      licence-requirements = "Oracle Database"
      "Patch Group"        = "RHEL"
    }
  }
}
