# Use `s3-db-restore-dir` tag to trigger a restore from backup. See
# https://github.com/ministryofjustice/modernisation-platform-configuration-management/blob/main/ansible/roles/db-restore
#
# Use `fixngo-connection-target` tag to monitor connectivity to a target in FixNGo.  See
# https://github.com/ministryofjustice/modernisation-platform-configuration-management/tree/main/ansible/roles/oracle-db-monitoring

locals {

  database_cloudwatch_metric_alarms = {
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
      dimensions = {
        instance = "oracle_ohasd"
      }
    }
    fixngo-connection = {
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "3"
      namespace           = "CWAgent"
      metric_name         = "collectd_exec_value"
      period              = "60"
      statistic           = "Average"
      threshold           = "1"
      alarm_description   = "this EC2 instance no longer has a connection to the Oracle Enterprise Manager in FixNGo of the connection-target machine"
      dimensions = {
        instance = "fixngo_connected" # required dimension value for this metric
      }
    }
  }

  database_cloudwatch_metric_alarms_lists = {
    database_dso = {
      parent_keys = []
      alarms_list = [
        { key = "ec2", name = "instance-status-check-failed-in-last-hour" },
        { key = "ec2", name = "system-status-check-failed-in-last-hour" },
        { key = "ec2_cwagent_linux", name = "free-disk-space-low-1hour" },
        { key = "ec2_cwagent_collectd", name = "chronyd-stopped" },
        { key = "ec2_cwagent_collectd", name = "sshd-stopped" },
        { key = "ec2_cwagent_collectd", name = "cloudwatch-agent-stopped" },
        { key = "ec2_cwagent_collectd", name = "ssm-agent-stopped" },
      ]
    }
    database_dba = {
      parent_keys = []
      alarms_list = [
        { key = "ec2", name = "cpu-utilization-high-15mins" },
        { key = "ec2", name = "instance-status-check-failed-in-last-hour" },
        { key = "ec2", name = "system-status-check-failed-in-last-hour" },
        { key = "ec2_cwagent_linux", name = "free-disk-space-low-1hour" },
        { key = "ec2_cwagent_linux", name = "high-memory-usage-15mins" },
        { key = "ec2_cwagent_linux", name = "cpu-iowait-high-3hour" },
        { key = "database", name = "oracle-db-disconnected" },
        { key = "database", name = "oracle-batch-failure" },
        { key = "database", name = "oracle-long-running-batch" },
        { key = "database", name = "oracleasm-service" },
        { key = "database", name = "oracle-ohasd-service" },
      ]
    }
    database_dba_high_priority = {
      parent_keys = []
      alarms_list = [
        { key = "database", name = "oracle-db-disconnected" },
      ]
    }
    fixngo_connection = {
      parent_keys = []
      alarms_list = [
        { key = "database", name = "fixngo-connection" },
      ]
    }
  }

  database_cloudwatch_log_groups = {
    cwagent-nomis-autologoff = {
      retention_in_days = 90
    }
  }

  database_ec2_default = {

    cloudwatch_metric_alarms = merge(
      module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso_pagerduty"].database_dso,
      module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dba_pagerduty"].database_dba
    )

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
      monitored            = "true"
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
