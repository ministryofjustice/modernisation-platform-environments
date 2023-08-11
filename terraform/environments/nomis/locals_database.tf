# Use `s3-db-restore-dir` tag to trigger a restore from backup. See
# https://github.com/ministryofjustice/modernisation-platform-configuration-management/blob/main/ansible/roles/db-restore
#
# Use `fixngo-connection-target` tag to monitor connectivity to a target in FixNGo.  See
# https://github.com/ministryofjustice/modernisation-platform-configuration-management/tree/main/ansible/roles/oracle-db-monitoring

locals {

  # Include this in ec2-instance ssm parameters if using oracle-db-standby-setup role with azure storage account
  database_azure_ssm_parameters = {
    prefix = "/database/"
    parameters = {
      az_sas_token = { description = "azure sas token for downloading azure DB backups" }
    }
  }

  # Include this in ec2-instance ssm parameters if using oracle-db-standby-setup role
  # The path should include the db_name as defined in ansible db_configs variable
  database_instance_ssm_parameters = {
    prefix = "/database/"
    parameters = {
      syspassword = {}
    }
  }

  # Include these in ec2-instance ssm parameters if using the misload role
  # paths are /database/<ec2_instance_name>/<each_parameter>
  database_ec2_misload_ssm_parameters = {
    prefix = "/database/"
    parameters = {
      misloadusername = {}
      misloadpassword = {}
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
  # TODO - change alarm actions to dba_pagerduty once alarms proven out
  database_ec2_cloudwatch_metric_alarms = merge(
    module.baseline_presets.cloudwatch_metric_alarms.ec2,
    module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
    {
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
        metric_name         = "collectd_exec_value"
        period              = "60"
        statistic           = "Average"
        threshold           = "1"
        alarm_description   = "oracleasm service has stopped"
        alarm_actions       = ["dba_pagerduty"]
        dimensions = {
          instance = "oracleasm"
        }
      }
      oracle-ohasd-service = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_exec_value"
        period              = "60"
        statistic           = "Average"
        threshold           = "1"
        alarm_description   = "oracle ohasd service has stopped"
        alarm_actions       = ["dba_pagerduty"]
        dimensions = {
          instance = "oracle_ohasd"
        }
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

  database_ec2_default = {

    cloudwatch_metric_alarms = local.database_ec2_cloudwatch_metric_alarms

    config = merge(module.baseline_presets.ec2_instance.config.db, {
      ami_name  = "nomis_rhel_7_9_oracledb_11_2_release_2022-10-07T12-48-08.562Z"
      ami_owner = "self"
    })

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

    user_data_cloud_init = {
      args = {
        branch               = "main"
        ansible_repo         = "modernisation-platform-configuration-management"
        ansible_repo_basedir = "ansible"
        ansible_args         = "--tags ec2provision"
      }
      scripts = [
        "ansible-ec2provision.sh.tftpl",
      ]
    }

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

    route53_records = {
      create_internal_record = true
      create_external_record = true
    }

    # See DSOS-1975: these random passwords cannot start with a digit
    ssm_parameters = {
      ASMSYS = {
        random = {
          length  = 30
          special = false
        }
        description = "ASMSYS password"
      }
      ASMSNMP = {
        random = {
          length  = 30
          special = false
        }
        description = "ASMSNMP password"
      }
    }

    tags = {
      ami                  = "nomis_rhel_7_9_oracledb_11_2"
      component            = "data"
      server-type          = "nomis-db"
      os-type              = "Linux"
      os-major-version     = 7
      os-version           = "RHEL 7.9"
      licence-requirements = "Oracle Database"
      "Patch Group"        = "RHEL"
    }
  }

  database_ec2_a = merge(local.database_ec2_default, {
    config = merge(local.database_ec2_default.config, {
      availability_zone = "${local.region}a"
    })
  })
  database_ec2_b = merge(local.database_ec2_default, {
    config = merge(local.database_ec2_default.config, {
      availability_zone = "${local.region}b"
    })
  })
}
