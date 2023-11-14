# nomis-production environment settings
locals {

  # baseline config
  production_config = {

    baseline_iam_policies = {
      Ec2ProdDatabasePolicy = {
        description = "Permissions required for prod Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "ssm:GetParameter",
              "ssm:PutParameter",
            ]
            resources = [
              "arn:aws:ssm:*:*:parameter/azure/*",
              "arn:aws:ssm:*:*:parameter/oracle/database/*P/*",
              "arn:aws:ssm:*:*:parameter/oracle/database/P*/*",
            ]
          },
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*P/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/P*/*",
            ]
          }
        ]
      }
    }

    baseline_ec2_instances = {
      pd-csr-db-a = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "hmpps_ol_8_5_oracledb_19c_release_2023-07-14T15-36-30.795Z"
          ami_owner         = "self"
          availability_zone = "${local.region}a"
          instance_profile_policies = concat(local.database_ec2.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type                = "r6i.xlarge"
          disable_api_termination      = true
          metadata_options_http_tokens = "optional" # the Oracle installer cannot accommodate a token
          monitoring                   = true
          vpc_security_group_ids       = ["database"]
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
          description = "PD CSR Oracle primary DB server"
          ami         = "base_ol_8_5"
          os-type     = "Linux"
          component   = "data"
          server-type = "csr-db"
          backup      = "false" # opt out of mod platform default backup plan
        }
      }

      pd-csr-db-b = merge(local.database_ec2, {
        config = merge(local.database_ec2.config, {
          ami_name          = "hmpps_ol_8_5_oracledb_19c_release_2023-07-14T15-36-30.795Z"
          availability_zone = "${local.region}b"
          instance_profile_policies = concat(local.database_ec2.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        instance = merge(local.database_ec2.instance, {
          instance_type                = "r6i.xlarge"
          disable_api_stop             = true
          metadata_options_http_tokens = "optional" # the Oracle installer cannot accommodate a token
        })

        ebs_volumes = merge(local.database_ec2.ebs_volumes, {
          "/dev/sda1" = { label = "root", size = 30 }
          "/dev/sdb"  = { label = "app", size = 100 } # /u01
          "/dev/sdc"  = { label = "app", size = 100 } # /u02
        })

        ebs_volume_config = merge(local.database_ec2.ebs_volume_config, {
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
        })
        
        ssm_parameters = {
          asm-passwords = {}
        }

        tags = {
          description = "PD CSR Oracle secondary DB server"
          ami         = "base_ol_8_5"
          os-type     = "Linux"
          component   = "data"
          server-type = "csr-db"
          backup      = "false" # opt out of mod platform default backup plan
        }
      })

      pd-csr-a-7-a = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "pd-csr-a-7-a"
          ami_owner                     = "self"
          availability_zone             = "${local.region}a"
          ebs_volumes_copy_all_from_ami = false
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type           = "m5.4xlarge"
          disable_api_termination = true
          disable_api_stop        = true
          monitoring              = true
          vpc_security_group_ids  = ["domain", "app", "jumpserver"]
          tags = {
            backup-plan         = "daily-and-weekly"
            instance-scheduling = "skip-scheduling"
          }
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 112 }
        }
        tags = {
          description       = "Migrated server PDCAW00007"
          app-config-status = "pending"
          csr-region        = "Region 1"
          os-type           = "Windows"
          ami               = "pd-csr-a-7-a"
          component         = "app"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      }


      pd-csr-w-1-a = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "pd-csr-w-1-a"
          ami_owner                     = "self"
          availability_zone             = "${local.region}a"
          ebs_volumes_copy_all_from_ami = false
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type           = "m5.4xlarge"
          disable_api_termination = true
          disable_api_stop        = true
          monitoring              = true
          vpc_security_group_ids  = ["domain", "web", "jumpserver"]
          tags = {
            backup-plan         = "daily-and-weekly"
            instance-scheduling = "skip-scheduling"
          }
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 112 }
        }
        tags = {
          description       = "Migrated server PDCWW00001"
          app-config-status = "pending"
          csr-region        = "Region 1 and 2"
          os-type           = "Windows"
          ami               = "pd-csr-w-1-a"
          component         = "web"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      }

      pd-csr-w-2-b = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "pd-csr-w-2-b"
          ami_owner                     = "self"
          availability_zone             = "${local.region}b"
          ebs_volumes_copy_all_from_ami = false
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type           = "m5.4xlarge"
          disable_api_termination = true
          disable_api_stop        = true
          monitoring              = true
          vpc_security_group_ids  = ["domain", "web", "jumpserver"]
          tags = {
            backup-plan         = "daily-and-weekly"
            instance-scheduling = "skip-scheduling"
          }
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 112 }
        }
        tags = {
          description       = "Migrated server PDCWW00002"
          app-config-status = "pending"
          csr-region        = "Region 1 and 2"
          os-type           = "Windows"
          ami               = "pd-csr-w-2-b"
          component         = "web"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      }

      pd-csr-w-3-a = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "pd-csr-w-3-a"
          ami_owner                     = "self"
          availability_zone             = "${local.region}a"
          ebs_volumes_copy_all_from_ami = false
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type           = "m5.4xlarge"
          disable_api_termination = true
          disable_api_stop        = true
          monitoring              = true
          vpc_security_group_ids  = ["domain", "web", "jumpserver"]
          tags = {
            backup-plan         = "daily-and-weekly"
            instance-scheduling = "skip-scheduling"
          }
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 112 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        tags = {
          description       = "Migrated server PDCWW00003"
          app-config-status = "pending"
          csr-region        = "Region 3 and 4"
          os-type           = "Windows"
          ami               = "pd-csr-w-3-a"
          component         = "web"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      }


    }
    baseline_route53_zones = {
      "csr.service.justice.gov.uk" = {

        records = [
          { name = "test", type = "NS", ttl = "86400", records = ["ns-1332.awsdns-38.org", "ns-2038.awsdns-62.co.uk", "ns-62.awsdns-07.com", "ns-689.awsdns-22.net"] },
          { name = "pp", type = "NS", ttl = "86400", records = ["ns-1408.awsdns-48.org", "ns-1844.awsdns-38.co.uk", "ns-447.awsdns-55.com", "ns-542.awsdns-03.net"] },
          { name = "piwfm", type = "A", ttl = "300", records = ["10.40.8.132"] },
          { name = "traina", type = "CNAME", ttl = "300", records = ["traina.pp.csr.service.justice.gov.uk"] },
          { name = "trainb", type = "CNAME", ttl = "300", records = ["trainb.pp.csr.service.justice.gov.uk"] },
        ]
      }
    }
  }
}
