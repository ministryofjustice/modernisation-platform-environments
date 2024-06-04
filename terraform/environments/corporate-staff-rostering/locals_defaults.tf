locals {

  ec2_cloudwatch_metric_alarms = {
    database = merge(
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2,
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_cwagent_linux,
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_instance_cwagent_collectd_oracle_db_backup,
      {
        cpu-utilization-high = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2["cpu-utilization-high"], {
          evaluation_periods  = "480"
          datapoints_to_alarm = "480"
          threshold           = "95"
          alarm_description   = "Triggers if the average cpu remains at 95% utilization or above for 8 hours to allow for DB refreshes. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4326064583"
        })
      },
      {
        cpu-iowait-high = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_cwagent_linux["cpu-iowait-high"], {
          evaluation_periods  = "480"
          datapoints_to_alarm = "480"
          threshold           = "40"
          alarm_description   = "Triggers if the amount of CPU time spent waiting for I/O to complete is continually high for 8 hours allowing for DB refreshes.  See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4325900634"
        })
      },
      {
        instance-or-cloudwatch-agent-stopped = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_instance_or_cwagent_stopped_linux["instance-or-cloudwatch-agent-stopped"], {
          threshold           = "0"
          evaluation_periods  = "5"
          datapoints_to_alarm = "2"
          period              = "60"
          alarm_description   = "Triggers if the instance or CloudWatch agent is stopped. Will check every 60 and trigger if there are 2 events in 5 minutes."
        })
      }
    )
    backup_database = merge(
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2,
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_cwagent_linux,
      {
        cpu-utilization-high = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2["cpu-utilization-high"], {
          evaluation_periods  = "480"
          datapoints_to_alarm = "480"
          threshold           = "95"
          alarm_description   = "Triggers if the average cpu remains at 95% utilization or above for 8 hours to allow for DB refreshes. See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4326064583"
        })
      },
      {
        cpu-iowait-high = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_cwagent_linux["cpu-iowait-high"], {
          evaluation_periods  = "480"
          datapoints_to_alarm = "480"
          threshold           = "40"
          alarm_description   = "Triggers if the amount of CPU time spent waiting for I/O to complete is continually high for 8 hours allowing for DB refreshes.  See https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4325900634"
        })
      },
      {
        instance-or-cloudwatch-agent-stopped = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_instance_or_cwagent_stopped_linux["instance-or-cloudwatch-agent-stopped"], {
          threshold           = "0"
          evaluation_periods  = "5"
          datapoints_to_alarm = "2"
          period              = "60"
          alarm_description   = "Triggers if the instance or CloudWatch agent is stopped. Will check every 60 and trigger if there are 2 events in 5 minutes."
        })
      }

    )
    web = merge(
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2,
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_cwagent_windows,
      local.application_log_metric_alarms.web,
      {
        instance-or-cloudwatch-agent-stopped = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_instance_or_cwagent_stopped_windows["instance-or-cloudwatch-agent-stopped"], {
          threshold           = "0"
          evaluation_periods  = "5"
          datapoints_to_alarm = "2"
          period              = "60"
          alarm_description   = "Triggers if the instance or CloudWatch agent is stopped. Will check every 60 and trigger if there are 2 events in 5 minutes."
        })
      }
    )
    app = merge(
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2,
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_cwagent_windows,
      local.application_log_metric_alarms.app,
      {
        instance-or-cloudwatch-agent-stopped = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_instance_or_cwagent_stopped_windows["instance-or-cloudwatch-agent-stopped"], {
          threshold           = "0"
          evaluation_periods  = "5"
          datapoints_to_alarm = "2"
          period              = "60"
          alarm_description   = "Triggers if the instance or CloudWatch agent is stopped. Will check every 60 and trigger if there are 2 events in 5 minutes."
        })
      },
      {
        high-memory-usage = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].ec2_cwagent_windows["high-memory-usage"], {
          threshold           = "75"
          period              = "60" # seconds
          evaluation_periods  = "20"
          datapoints_to_alarm = "20"
          alarm_description   = "Triggers if the average memory utilization is 75% or above for 20 minutes. Set below the default of 95% to allow enough time to establish an RDP session to fix the issue."
        })
      }
    )
  }

  defaults_ec2 = {
    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_owner                     = "self"
      ebs_volumes_copy_all_from_ami = false
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      disable_api_termination = true
      disable_api_stop        = false
      monitoring              = true
      tags = {
        backup-plan         = "daily-and-weekly"
        instance-scheduling = "skip-scheduling"
      }
    })
    route53_records = module.baseline_presets.ec2_instance.route53_records.internal_and_external
  }

  defaults_database_ec2 = merge(local.defaults_ec2, {
    cloudwatch_metric_alarms = local.ec2_cloudwatch_metric_alarms.database
    instance = merge(local.defaults_ec2.instance, {
      disable_api_termination      = true
      disable_api_stop             = false
      instance_type                = "r6i.xlarge"
      metadata_options_http_tokens = "optional" # the Oracle installer cannot accommodate a token
      vpc_security_group_ids       = ["database"]
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
    route53_records        = module.baseline_presets.ec2_instance.route53_records.internal_and_external
    secretsmanager_secrets = module.baseline_presets.ec2_instance.secretsmanager_secrets.oracle_19c
    user_data_cloud_init   = module.baseline_presets.ec2_instance.user_data_cloud_init.ansible
    tags = {
      ami         = "base_ol_8_5"
      backup      = "false" # disable mod platform backup since we use our own policies
      os-type     = "Linux"
      component   = "data"
      server-type = "csr-db"
    }
  })


  defaults_app_ec2 = merge(local.defaults_ec2, {
    cloudwatch_metric_alarms = local.ec2_cloudwatch_metric_alarms.app
    instance = merge(local.defaults_ec2.instance, {
      vpc_security_group_ids = ["domain", "app", "jumpserver"]
    })
    tags = {
      backup    = "false" # disable mod platform backup since we use our own policies
      os-type   = "Windows"
      component = "app"
    }
  })

  defaults_web_ec2 = merge(local.defaults_ec2, {
    instance = merge(local.defaults_ec2.instance, {
      vpc_security_group_ids = ["domain", "web", "jumpserver"]
    })
    cloudwatch_metric_alarms = local.ec2_cloudwatch_metric_alarms.web
    tags = {
      backup    = "false" # disable mod platform backup since we use our own policies
      os-type   = "Windows"
      component = "web"
    }
  })

}
