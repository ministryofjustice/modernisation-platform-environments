locals {

  ec2_cloudwatch_metric_alarms = {
    linux = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux
    )
    windows = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows
    )
  }

  defaults_ec2 = {
    cloudwatch_metric_alarms = local.ec2_cloudwatch_metric_alarms.windows
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
  }

  defaults_database_ec2 = merge(local.defaults_ec2, {
    instance = merge(local.defaults_ec2.instance, {
      disable_api_stop       = false
      vpc_security_group_ids = ["database"]
    })
    cloudwatch_metric_alarms = local.ec2_cloudwatch_metric_alarms.linux
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
    route53_records      = module.baseline_presets.ec2_instance.route53_records.internal_and_external
    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ansible
  })

  defaults_app_ec2 = merge(local.defaults_ec2, {
    instance = merge(local.defaults_ec2.instance, {
      vpc_security_group_ids = ["domain", "app", "jumpserver"]
    })
  })

  defaults_web_ec2 = merge(local.defaults_ec2, {
    instance = merge(local.defaults_ec2.instance, {
      vpc_security_group_ids = ["domain", "web", "jumpserver"]
    })
  })

}
