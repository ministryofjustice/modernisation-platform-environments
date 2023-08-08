locals {

  oem_database_instance_ssm_parameters = {
    prefix = "/database/"
    parameters = {
      rcvcatownerpassword = {}
      syspassword         = {}
      systempassword      = {}
    }
  }
  oem_emrep_ssm_parameters = {
    prefix = "/oem/"
    parameters = {
      sysmanpassword = {}
      syspassword    = {}
      systempassword = {}
    }
  }
  oem_ssm_parameters = {
    prefix = "/oem/"
    parameters = {
      agentregpassword    = {}
      nodemanagerpassword = {}
      weblogicpassword    = {}
    }
  }

  oem_ec2_default = {

    autoscaling_group = module.baseline_presets.ec2_autoscaling_group.default

    config = merge(module.baseline_presets.ec2_instance.config.db, {
      ami_name  = "hmpps_ol_8_5_oracledb_19c_release_2023-08-07T16-14-04.275Z"
      ami_owner = "self"
    })

    instance = merge(module.baseline_presets.ec2_instance.instance.default_db, {
      vpc_security_group_ids = ["data-oem"]
    })

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
      data  = { total_size = 100 }
      flash = { total_size = 50 }
    }

    route53_records = {
      create_internal_record = true
      create_external_record = true
    }

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
      ami                  = "hmpps_ol_8_5_oracledb_19c" # not including as hardening role seems to cause an issue
      component            = "data"
      server-type          = "hmpps-oem"
      os-type              = "Linux"
      os-major-version     = 8
      os-version           = "OL 8.5"
      licence-requirements = "Oracle Enterprise Management"
    }
  }
}
