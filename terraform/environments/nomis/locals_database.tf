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

  database_ec2_cloudwatch_metric_alarms = {
    standard = merge(
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2,
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2_cwagent_linux,
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dso_pagerduty"].ec2_instance_cwagent_collectd_service_status_os,
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2_instance_cwagent_collectd_service_status_app,
      local.environment == "production" ? {} : {
        cpu-utilization-high = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2["cpu-utilization-high"], {
          evaluation_periods  = "480"
          datapoints_to_alarm = "480"
          threshold           = "95"
          alarm_description   = "Triggers if the average cpu remains at 95% utilization or above for 8 hours to allow for DB refreshes. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4326064583"
        })
        cpu-iowait-high = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2_cwagent_linux["cpu-iowait-high"], {
          evaluation_periods  = "480"
          datapoints_to_alarm = "480"
          threshold           = "40"
          alarm_description   = "Triggers if the amount of CPU time spent waiting for I/O to complete is continually high for 8 hours allowing for DB refreshes.  See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4325900634"
        })
      },
    )
    connectivity_test = merge(
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dso_pagerduty"].ec2_instance_cwagent_collectd_connectivity_test,
    )
    db_connected = merge(
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_high_priority_pagerduty"].ec2_instance_cwagent_collectd_oracle_db_connected,
    )
    db_backup = merge(
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2_instance_cwagent_collectd_oracle_db_backup,
    )
    nomis_batch = merge(
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2_instance_cwagent_collectd_textfile_monitoring
    )
    misload = merge(
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dba_pagerduty"].ec2_instance_cwagent_collectd_textfile_monitoring, {
        misload-long-running = {
          comparison_operator = "GreaterThanOrEqualToThreshold"
          evaluation_periods  = "1"
          datapoints_to_alarm = "1"
          namespace           = "CWAgent"
          metric_name         = "collectd_textfile_monitoring_seconds"
          period              = "300"
          statistic           = "Maximum"
          threshold           = "14400"
          treat_missing_data  = "notBreaching"
          alarm_description   = "Triggers if misload process is taking longer than 4 hours, see https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4615798942"
          alarm_actions       = ["dba_pagerduty"]
          dimensions = {
            type          = "duration"
            type_instance = "misload_running"
          }
        }
    })
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
      ami                         = "nomis_rhel_7_9_oracledb_11_2"
      backup                      = "false" # disable mod platform backup since we use our own policies
      component                   = "data"
      server-type                 = "nomis-db"
      os-type                     = "Linux"
      os-major-version            = 7
      os-version                  = "RHEL 7.9"
      licence-requirements        = "Oracle Database"
      "Patch Group"               = "RHEL"
      OracleDbLTS-ManagedInstance = true # oracle license tracking
    }
  }
}
