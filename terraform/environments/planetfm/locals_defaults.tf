locals {

  defaults_ec2 = {
    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_owner                     = "self"
      ebs_volumes_copy_all_from_ami = false
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      disable_api_termination = true
      disable_api_stop        = true
      monitoring              = true
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
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows
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
      vpc_security_group_ids = ["domain", "app", "jumpserver"]
    })
    tags = merge(local.defaults_ec2.tags, {
      component = "app"
    })
  })

  defaults_web_ec2 = merge(local.defaults_ec2, {
    instance = merge(local.defaults_ec2.instance, {
      vpc_security_group_ids = ["domain", "web", "jumpserver"]
    })
    tags = merge(local.defaults_ec2.tags, {
      component = "web"
    })
  })

}
