# nomis-production environment settings
locals {

  # baseline config
  production_config = {
    baseline_ec2_instances = {
      pd-csr-db-a = {
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
          tags = {
            backup-plan = "daily-and-weekly"
          }
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
            total_size = 1000
          }
          flash = {
            iops       = 3000
            throughput = 125
            total_size = 100
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
          description = "PD CSR DB server"
          ami         = "base_ol_8_5"
          os-type     = "Linux"
          component   = "data"
          server-type = "csr-db"
          backup      = "false" # opt out of mod platform default backup plan
        }
      }
    }
  }
}
