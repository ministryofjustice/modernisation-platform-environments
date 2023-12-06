# Use `s3-db-restore-dir` tag to trigger a restore from backup. See
# https://github.com/ministryofjustice/modernisation-platform-configuration-management/blob/main/ansible/roles/db-restore
#
# Use `fixngo-connection-target` tag to monitor connectivity to a target in FixNGo.  See
# https://github.com/ministryofjustice/modernisation-platform-configuration-management/tree/main/ansible/roles/oracle-db-monitoring

locals {

  database_nomis_secretsmanager_secrets = {
    secrets = {
      passwords          = { description = "database passwords" }
      weblogic-passwords = { description = "passwords available to weblogic servers" }
    }
  }
  database_mis_secretsmanager_secrets = {
    secrets = {
      passwords      = { description = "database passwords" }
      misload-config = { description = "misload username, password and hostname" }
    }
  }
  database_secretsmanager_secrets = {
    secrets = {
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

    secretsmanager_secrets = module.baseline_presets.ec2_instance.secretsmanager_secrets.oracle_11g

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
