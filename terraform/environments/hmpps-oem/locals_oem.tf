locals {

  oem_ec2_default = {

    autoscaling_group = module.baseline_presets.ec2_autoscaling_group.default

    config = merge(module.baseline_presets.ec2_instance.config.db, {
      ami_name = "base_ol_8_5_*"
    })

    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      instance_type                = "r6i.xlarge"
      disable_api_termination      = true
      metadata_options_http_tokens = "optional" # the Oracle installer cannot accommodate a token
      monitoring                   = true
      vpc_security_group_ids       = ["data-oem"]
    })

    user_data_cloud_init = {
      args = {
        branch               = "main"
        ansible_repo         = "modernisation-platform-configuration-management"
        ansible_repo_basedir = "ansible"
        ansible_args         = "--tags ec2provision,oracle_19c_download,oracle_19c_install"
      }
      scripts = [
        "ansible-ec2provision.sh.tftpl",
      ]
    }

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
      data = {
        iops       = 3000
        throughput = 125
        total_size = 100
      }
      flash = {
        iops       = 3000
        throughput = 125
        total_size = 50
      }
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
      # ami                = "base_ol_8_5"  # not including as hardening role seems to cause an issue
      component            = "data"
      server-type          = "hmpps-oem"
      os-type              = "Linux"
      os-major-version     = 8
      os-version           = "OL 8.5"
      licence-requirements = "Oracle Enterprise Management"
    }
  }
}
