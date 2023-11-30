locals {

  database_ssm_parameters = {
    parameters = {
      passwords = { description = "database passwords" }
    }
  }

  database_ec2_cloudwatch_metric_alarms = merge(
    module.baseline_presets.cloudwatch_metric_alarms.ec2,
    module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
    module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status, {
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
        alarm_actions       = ["dso_pagerduty"]
      }
  })

  database_ec2_misload_cloudwatch_metric_alarms = {
    misload_error = {
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "1"
      datapoints_to_alarm = "1"
      namespace           = "CWAgent"
      metric_name         = "collectd_textfile_monitoring_value"
      period              = "300"
      statistic           = "Maximum"
      threshold           = "1"
      alarm_description   = "Triggers if misload process failed. See nomis-misload and collectd-textfile-monitoring ansible roles"
      alarm_actions       = ["dso_pagerduty"]
      dimensions = {
        type          = "gauge"
        type_instance = "misload_status"
      }
    }
    misload_metric_not_updated = {
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "1"
      datapoints_to_alarm = "1"
      namespace           = "CWAgent"
      metric_name         = "collectd_textfile_monitoring_seconds"
      period              = "300"
      statistic           = "Maximum"
      threshold           = "129600"
      treat_missing_data  = "breaching"
      alarm_description   = "Triggers if misload status metric missing or not updated or over 36 hours"
      alarm_actions       = ["dso_pagerduty"]
      dimensions = {
        type          = "duration"
        type_instance = "misload_status"
      }
    }
    misload_long_running = {
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "1"
      datapoints_to_alarm = "1"
      namespace           = "CWAgent"
      metric_name         = "collectd_textfile_monitoring_seconds"
      period              = "300"
      statistic           = "Maximum"
      threshold           = "14400"
      treat_missing_data  = "notBreaching"
      alarm_description   = "Triggers if misload process is taking longer than 4 hours"
      alarm_actions       = ["dso_pagerduty"]
      dimensions = {
        type          = "duration"
        type_instance = "misload_running"
      }
    }
  }

  database_ec2_default = {

    config = merge(module.baseline_presets.ec2_instance.config.db, {
      ami_name  = "hmpps_ol_8_5_oracledb_19c_release_2023-08-08T13-49-56.195Z"
      ami_owner = "self"
    })

    instance = module.baseline_presets.ec2_instance.instance.default_db

    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible

    ebs_volumes = {
      "/dev/sdb" = { type = "gp3", label = "app", size = 100 } # /u01
      "/dev/sdc" = { type = "gp3", label = "app", size = 100 } # /u02
      "/dev/sde" = { type = "gp3", label = "data" }            # DATA01
      "/dev/sdf" = { type = "gp3", label = "data" }            # DATA02
      "/dev/sdg" = { type = "gp3", label = "data" }            # DATA03
      "/dev/sdh" = { type = "gp3", label = "data" }            # DATA04
      "/dev/sdi" = { type = "gp3", label = "data" }            # DATA05
      "/dev/sdj" = { type = "gp3", label = "flash" }           # FLASH01
      "/dev/sdk" = { type = "gp3", label = "flash" }           # FLASH02
      "/dev/sds" = { type = "gp3", label = "swap" }
    }

    ebs_volume_config = {
      data  = { total_size = 500 }
      flash = { total_size = 50 }
    }

    route53_records = module.baseline_presets.ec2_instance.route53_records.internal_and_external

    ssm_parameters = {
      asm-passwords = {}
    }

    tags = {
      ami                  = "hmpps_ol_8_5_oracledb_19c"
      component            = "data"
      server-type          = "ncr-db"
      os-type              = "Linux"
      os-version           = "RHEL 8.5"
      licence-requirements = "Oracle Database"
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
