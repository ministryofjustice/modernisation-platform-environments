locals {

  defaults_ec2 = {
    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_owner                     = "self"
      ebs_volumes_copy_all_from_ami = false
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      tags = {
        backup-plan         = "daily-and-weekly"
        instance-scheduling = "skip-scheduling"
      }
    })
    tags = {
      os-type = "Windows"
    }
    cloudwatch_metric_alarms = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows,
      {
        instance-or-cloudwatch-agent-stopped = merge(module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["planetfm_pagerduty"].ec2_instance_or_cwagent_stopped_windows["instance-or-cloudwatch-agent-stopped"], {
          threshold           = "0"
          evaluation_periods  = "5"
          datapoints_to_alarm = "2"
          period              = "60"
          alarm_description   = "Triggers if the instance or CloudWatch agent is stopped. Will check every 60 and trigger if there are 2 events in 5 minutes."
        })
      }
    )
    route53_records = module.baseline_presets.ec2_instance.route53_records.internal_and_external
  }

  defaults_database_ec2 = merge(local.defaults_ec2, {
    instance = merge(local.defaults_ec2.instance, {
      vpc_security_group_ids = ["domain", "database", "jumpserver"]
    })
    tags = merge(local.defaults_ec2.tags, {
      component = "database"
    })
  })

  defaults_app_ec2 = merge(local.defaults_ec2, {
    instance = merge(local.defaults_ec2.instance, {
      vpc_security_group_ids = ["domain", "app", "jumpserver", "remotedesktop_sessionhost"]
    })
    tags = merge(local.defaults_ec2.tags, {
      component = "app"
    })
  })

  defaults_web_ec2 = merge(local.defaults_ec2, {
    instance = merge(local.defaults_ec2.instance, {
      vpc_security_group_ids = ["domain", "web", "jumpserver", "remotedesktop_sessionhost"]
    })
    tags = merge(local.defaults_ec2.tags, {
      component = "web"
    })
  })

}
