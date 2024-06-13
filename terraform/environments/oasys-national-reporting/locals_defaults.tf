locals {

  ec2_cloudwatch_metric_alarms = {
    web = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
    )
    boe = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
    )
    bods = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows,
    )
    onr_db = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
    )
  }

  database_secretsmanager_secrets = {
    secrets = {
      passwords = { description = "database passwords" }
    }
  }

  web_secretsmanager_secrets = {
    secrets = {
      passwords = { description = "Web Passwords" }
    }
  }

  boe_secretsmanager_secrets = {
    secrets = {
      passwords = { description = "BOE Passwords" }
    }
  }

  bods_secretsmanager_secrets = {
    secrets = {
      passwords = { description = "BODS Passwords" }
    }
  }

  defaults_ec2 = {
    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_owner                     = "self"
      ebs_volumes_copy_all_from_ami = false
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      disable_api_termination = false # TODO: change this later when instances are live
      disable_api_stop        = false # TODO: agree this setting with the nart team
      monitoring              = false # TODO: change this later when instances are live
      tags = {
        backup-plan         = "daily-and-weekly"
        instance-scheduling = "skip-scheduling"
      }
    })
    route53_records = module.baseline_presets.ec2_instance.route53_records.internal_and_external
  }

  defaults_web_ec2 = merge(local.defaults_ec2, {
    config = merge(local.defaults_ec2.config, {
      ami_name = "base_rhel_7_9_*"
    })
    instance = merge(local.defaults_ec2.instance, {
      vpc_security_group_ids = ["web"]
    })
    tags = {
      ami         = "base_rhel_7_9"
      os-type     = "Linux"
      component   = "web"
      server-type = "onr-web"
    }
    ebs_volumes = {
      "/dev/sda1" = { type = "gp3", size = 32 }  # root volume
      "/dev/sdb"  = { type = "gp3", size = 128 } # /u01
      "/dev/sdc"  = { type = "gp3", size = 128 } # /u02
    }
    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible

    # cloudwatch_metric_alarms = local.ec2_cloudwatch_metric_alarms.web off for now
  })

  defaults_boe_ec2 = merge(local.defaults_ec2, {
    config = merge(local.defaults_ec2.config, {
      ami_owner = "374269020027"
      ami_name  = "base_rhel_6_10_*"
    })
    instance = merge(local.defaults_ec2.instance, {
      vpc_security_group_ids       = ["boe", "oasys_db"]
      metadata_options_http_tokens = "optional" # required as Rhel 6 cloud-init does not support IMDSv2
    })
    # cloudwatch_metric_alarms = local.ec2_cloudwatch_metric_alarms.boe off for now
    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
    tags = {
      ami         = "base_rhel_6_10"
      os-type     = "Linux"
      component   = "boe"
      server-type = "onr-boe"
    }
    # FIXME: ebs_volumes list is NOT YET CORRECT and will need to change
    ebs_volumes = {
      "/dev/sda1" = { type = "gp3", size = 128 } # root volume
      "/dev/sdb"  = { type = "gp3", size = 128 } # /u01
      "/dev/sdc"  = { type = "gp3", size = 128 } # /u02
      "/dev/sds"  = { type = "gp3", size = 128 } # swap
    }
  })

  defaults_bods_ec2 = merge(local.defaults_ec2, {
    config = merge(local.defaults_ec2.config, {
      ami_name                      = "hmpps_windows_server_2019_release_*" # wildcard to latest. EC2 instance versions ami_name must be fixed
      ebs_volumes_copy_all_from_ami = false
      user_data_raw                 = module.baseline_presets.ec2_instance.user_data_raw["user-data-pwsh"]
    })
    instance = merge(local.defaults_ec2.instance, {
      vpc_security_group_ids = ["bods", "oasys_db"]
    })
    # cloudwatch_metric_alarms = local.ec2_cloudwatch_metric_alarms.bods off for now
    tags = {
      os-type   = "Windows"
      component = "onr_bods"
    }
    # FIXME: ebs_volumes list is NOT YET CORRECT and will need to change
    ebs_volumes = {
      "/dev/sda1" = { type = "gp3", size = 128 } # root volume
    }
  })

  # defaults_onr_db_ec2 = merge(local.defaults_ec2, {
  #   config = merge(local.defaults_ec2.config, {
  #     ami_name = "base_rhel_7_9_*"
  #   })
  #   instance = merge(local.defaults_ec2.instance, {
  #     disable_api_stop       = false
  #     vpc_security_group_ids = ["onr_db", "oasys_db_onr_db"]
  #   })
  #   # FIXME: ebs_volumes list is NOT YET CORRECT and will need to change
  #   ebs_volumes = {
  #     "/dev/sda1" = { label = "root", size = 30 }   # root volume
  #     "/dev/sdb"  = { label = "app", size = 128 }   # /u01
  #     "/dev/sdc"  = { label = "app", size = 128 }   # /u02
  #     "/dev/sde"  = { label = "data", size = 1023 } # DATA01
  #     # "/dev/sdf" = { label = "data", size = 1023 }  # DATA02
  #     # "/dev/sdg" = { label = "data", size = 1023 }  # DATA03
  #     # "/dev/sdh" = { label = "data", size = 1023 }  # DATA04
  #     # "/dev/sdi" = { label = "data", size = 1023 }  # DATA05
  #     # "/dev/sdj" = { label = "data", size = 1023 } # DATA06
  #     "/dev/sdk" = { label = "flash", size = 1023 } # FLASH01
  #     # "/dev/sdl" = { label = "flash", size = 1023 } # FLASH02
  #     # "/dev/sdm" = { label = "flash", size = 1023 } # FLASH03
  #     # "/dev/sdn" = { label = "flash", size = 1023 } # FLASH04
  #     # "/dev/sdo" = { label = "flash", size = 1023 } # FLASH05
  #     # "/dev/sdp" = { label = "flash", size = 1023 } # FLASH06
  #     # "/dev/sdq" = { label = "flash", size = 1023 } # FLASH07
  #     "/dev/sds" = { label = "swap", size = 128 }
  #   }
  #   ebs_volume_config = {
  #     data = {
  #       iops       = 5000 # confirmed, by looking at Azure
  #       throughput = 200
  #     }
  #     flash = {
  #       iops       = 5000 # confirmed, by looking at Azure
  #       throughput = 200
  #     }
  #   }
  #   # cloudwatch_metric_alarms = local.ec2_cloudwatch_metric_alarms.onr_db off for now
  #   tags = {
  #     os-type   = "Linux"
  #     component = "onr_db"
  #   }
  #   route53_records = module.baseline_presets.ec2_instance.route53_records.internal_and_external
  # })
}
