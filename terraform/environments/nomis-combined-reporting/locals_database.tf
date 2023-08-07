locals {

  oracle_ec2_default = {

    config = merge(module.baseline_presets.ec2_instance.config.db, {
      ami_name  = "hmpps_ol_8_5_oracledb_19c_release_2023-07-14T15-36-30.795Z"
      ami_owner = "self"
    })

    instance              = module.baseline_presets.ec2_instance.instance.default_db
    autoscaling_schedules = {}
    autoscaling_group     = module.baseline_presets.ec2_autoscaling_group.default
    user_data_cloud_init  = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags

    ebs_volumes = {
      "/dev/sdb" = { # /u01
        size  = 100
        label = "app"
        type  = "gp3"
      }
      "/dev/sdc" = { # /u02
        size  = 500
        label = "app"
        type  = "gp3"
      }
      "/dev/sde" = { # DATA01
        label = "data"
        size  = 500
        type  = "gp3"
      }
      # "/dev/sdf" = {  # DATA02
      #   label = "data"
      #   type = null
      # }
      # "/dev/sdg" = {  # DATA03
      #   label = "data"
      #   type = null
      # }
      # "/dev/sdh" = {  # DATA04
      #   label = "data"
      #   type = null
      # }
      # "/dev/sdi" = {  # DATA05
      #   label = "data"
      #   type = null
      # }
      "/dev/sdj" = { # FLASH01
        label = "flash"
        type  = "gp3"
        size  = 50
      }
      # "/dev/sdk" = { # FLASH02
      #   label = "flash"
      #   type = null
      # }
      "/dev/sds" = {
        label = "swap"
        type  = "gp3"
        size  = 2
      }
    }
    ebs_volume_config = {
      data = {
        iops       = 3000
        type       = "gp3"
        throughput = 125
        total_size = 200
      }
      flash = {
        iops       = 3000
        type       = "gp3"
        throughput = 125
        total_size = 50
      }
    }
    route53_records = module.baseline_presets.ec2_instance.route53_records.internal_and_external
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
    # Example target group setup below
    lb_target_groups = {}

    tags = {
      ami                  = "hmpps_ol_8_5_oracledb_19c"
      component            = "data"
      server-type          = "ncr-db"
      os-type              = "Linux"
      os-version           = "RHEL 8.5"
      licence-requirements = "Oracle Database"
    }
  }

}