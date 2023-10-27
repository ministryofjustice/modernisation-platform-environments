# nomis-test environment settings
locals {

  # baseline config
  test_config = {

    baseline_ssm_parameters = {
      "/oracle/database/T3IWFM" = local.database_ssm_parameters
    }

    baseline_ec2_instances = {
      t3-csr-db-a = merge(local.database_ec2, {
        config = merge(local.database_ec2.config, {
          ami_name          = "hmpps_ol_8_5_oracledb_19c_release_2023-07-14T15-36-30.795Z"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.database_ec2.instance, {
          instance_type                = "r6i.xlarge"
          metadata_options_http_tokens = "optional" # the Oracle installer cannot accommodate a token
        })

        ebs_volumes = merge(local.database_ec2.ebs_volumes, {
          "/dev/sda1" = { label = "root", size = 30 }
          "/dev/sdb"  = { label = "app", size = 100 }
          "/dev/sdc"  = { label = "app", size = 100 }
        })

        ebs_volume_config = merge(local.database_ec2.ebs_volume_config, {
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
        })

        ssm_parameters = {
          asm-passwords = {}
        }

        tags = {
          description = "Test CSR DB server"
          ami         = "base_ol_8_5"
          os-type     = "Linux"
          component   = "test"
          server-type = "csr-db"
        }
      })
    }
    baseline_ec2_autoscaling_groups = {
      /* web-srv-1 = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "web-test-server-ami"
          ami_owner                     = "self"
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = base64encode(file("./templates/web-server-user-data.yaml"))
          instance_profile_policies     = concat(module.baseline_presets.ec2_instance.config.default.instance_profile_policies, ["CSRWebServerPolicy"])
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["sg-0f692e412a94bbe9c"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 256 }
        }
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0 # set to 0 while testing
        })
        tags = {
          description = "Test Restore Windows Server 2012 R2"
          os-type     = "Windows"
          component   = "webserver"
          server-type = "csr-web-server"
        }
      } */
      app-srv-3 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "app-test-server-ami-lv2-drv"
          ami_owner                     = "self"
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = base64encode(file("./templates/app-server-user-data.yaml"))
          instance_profile_policies     = concat(module.baseline_presets.ec2_instance.config.default.instance_profile_policies, ["CSRWebServerPolicy"])
        })

        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["migration-app-sg"]
          tags = {
            backup-plan = "daily-and-weekly"
          }
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 256 }
        }
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0 # set to 0 while testing
        })
        tags = {
          description = "Test Restore Windows Server 2012 R2 includes Ec2LaunchV2 NVMe and PV drivers"
          os-type     = "Windows"
          component   = "appserver"
          server-type = "csr-app-server"
        }
      }
      app-srv-4 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "app-test-server-ami-lv2-drv-r1"
          ami_owner                     = "self"
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = base64encode(file("./templates/app-server-user-data.yaml"))
          instance_profile_policies     = concat(module.baseline_presets.ec2_instance.config.default.instance_profile_policies, ["CSRWebServerPolicy"])
        })

        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["migration-app-sg"]
          tags = {
            backup-plan = "daily-and-weekly"
          }
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 256 }
        }
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0 # set to 0 while testing
        })
        tags = {
          description = "Test Restore Windows Server 2012 R2 includes Ec2LaunchV2 NVMe PV drivers without run-once file"
          os-type     = "Windows"
          component   = "appserver"
          server-type = "csr-app-server"
        }
      }
    }
    baseline_route53_zones = {
      "test.csr.service.justice.gov.uk" = {
        records = [
          { name = "t3iwfm", type = "CNAME", ttl = "300", records = ["t3-csr-db-a.corporate-staff-rostering.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
        ]
      }
    }


    baseline_s3_buckets = {
      # use this bucket for storing artefacts for use across all accounts
      csr-software = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
          module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy,
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
      }
    }

  }
}
