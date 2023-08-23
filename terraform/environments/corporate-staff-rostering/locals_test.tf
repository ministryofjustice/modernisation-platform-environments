# nomis-test environment settings
locals {

  # baseline config
  test_config = {

    baseline_ec2_instances = {
      t3-csr-db-a = {
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

        tags = {
          description = "Test CSR DB server"
          ami         = "base_ol_8_5"
          os-type     = "Linux"
          component   = "test"
          server-type = "csr-db"
        }
      }
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
      app-srv-1 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "app-test-server-ami"
          ami_owner                     = "self"
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = base64encode(file("./templates/app-server-user-data.yaml"))
          # instance_profile_policies     = concat(module.baseline_presets.ec2_instance.config.default.instance_profile_policies, ["CSRWebServerPolicy"])
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
          component   = "appserver"
          server-type = "csr-app-server"
        }
      }
    }
    baseline_route53_zones = {
      "hmpps-test.modernisation-platform.service.justice.gov.uk" = {
        records = [
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
