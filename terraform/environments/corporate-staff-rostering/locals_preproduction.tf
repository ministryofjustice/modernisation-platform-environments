# nomis-preproduction environment settings
locals {

  # baseline config
  preproduction_config = {

    baseline_ec2_instances = {
      pp-csr-db-a = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "hmpps_ol_8_5_oracledb_19c_release_2023-07-14T15-36-30.795Z"
          ami_owner         = "self"
          availability_zone = "${local.region}a"
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type                = "r6i.xlarge"
          disable_api_termination      = true
          metadata_options_http_tokens = "optional" # the Oracle installer cannot accommodate a token
          monitoring                   = true
          vpc_security_group_ids       = ["data-db"]
        })

        user_data_cloud_init = {
          args = {
            branch               = "main"
            ansible_repo         = "modernisation-platform-configuration-management"
            ansible_repo_basedir = "ansible"
            ansible_args         = "--tags ec2provision"
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
            total_size = 500
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
          asm-passwords = {}
        }

        tags = {
          description = "PP CSR DB server"
          ami         = "base_ol_8_5"
          os-type     = "Linux"
          component   = "test"
          server-type = "csr-db"
        }
      }

      pp-csr-w-7-b = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "pp-csr-w-7-b"
          ami_owner                     = "self"
          availability_zone             = "${local.region}b"
          ebs_volumes_copy_all_from_ami = false
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type           = "m5.2xlarge"
          disable_api_termination = true
          monitoring              = true
          vpc_security_group_ids  = ["migration-web-sg", "domain-controller"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 56 }
        }
        tags = {
          description = "copy of PPCWW00007 for csr ${local.environment}"
          os-type     = "Windows"
          ami         = "pp-csr-w-7-b"
          component   = "web"
        }
      }

      pp-csr-w-8-b = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "pp-csr-w-8-b"
          ami_owner                     = "self"
          availability_zone             = "${local.region}b"
          ebs_volumes_copy_all_from_ami = false
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type           = "m5.2xlarge"
          disable_api_termination = true
          monitoring              = true
          vpc_security_group_ids  = ["migration-web-sg", "domain-controller"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 200 }
          "/dev/sdb"  = { type = "gp3", size = 56 }
        }
        tags = {
          description = "copy of PPCWW00008 for csr ${local.environment}"
          os-type     = "Windows"
          ami         = "pp-csr-w-8-b"
          component   = "web"
        }
      }
    }

    baseline_ec2_autoscaling_groups = {
      prepprod-tst-1 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2023-*" # Microsoft Windows Server 2019 Base
          ami_owner                     = "754260907303"
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = base64encode(file("./templates/test-user-data.yaml"))
          instance_profile_policies     = concat(module.baseline_presets.ec2_instance.config.default.instance_profile_policies, ["CSRWebServerPolicy"])
        })

        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["migration-web-sg", "domain-controller"]
          instance_type          = "t3.medium"

        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 256 }
        }
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0 # set to 0 while testing
        })
        tags = {
          description = "Test Windows Web Server 2019"
          os-type     = "Windows"
          component   = "Test"
          server-type = "test-windows-server"
        }
      }
    }

    baseline_route53_zones = {
      "hmpps-preproduction.modernisation-platform.service.justice.gov.uk" = {
        records = [
        ]
      }
    }
  }
}



