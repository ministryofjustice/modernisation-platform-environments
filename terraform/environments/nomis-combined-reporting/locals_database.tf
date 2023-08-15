locals {

  database_ec2_default = {

    config = merge(module.baseline_presets.ec2_instance.config.db, {
      ami_name  = "hmpps_ol_8_5_oracledb_19c_release_2023-08-08T13-49-56.195Z"
      ami_owner = "self"
    })

    instance = module.baseline_presets.ec2_instance.instance.default_db

    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible

    ebs_volumes = {
      "/dev/sdb" = { type = "gp3", label = "app", size = 100 }              # /u01
      "/dev/sdc" = { type = "gp3", label = "app", size = 100 }              # /u02
      "/dev/sde" = { type = "gp3", label = "data"}                          # DATA01
      "/dev/sdf" = { type = "gp3", label = "data"}                          # DATA02
      "/dev/sdg" = { type = "gp3", label = "data"}                          # DATA03
      "/dev/sdh" = { type = "gp3", label = "data"}                          # DATA04
      "/dev/sdi" = { type = "gp3", label = "data"}                          # DATA05
      "/dev/sdj" = { type = "gp3", label = "flash" }                        # FLASH01
      "/dev/sdk" = { type = "gp3", label = "flash" }                        # FLASH02
      "/dev/sds" = { type = "gp3", label = "swap" }
    }

    ebs_volume_config = {
      data  = { total_size = 500 }
      flash = { total_size = 50 }
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
