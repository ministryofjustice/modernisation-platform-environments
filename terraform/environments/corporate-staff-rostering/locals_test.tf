# nomis-test environment settings
locals {

  # baseline config
  test_config = {

    baseline_ec2_instances = {
      test-2022 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2024-01-24T14-27-49.703Z"
          ami_owner                     = "self"
          ebs_volumes_copy_all_from_ami = false
          instance_profile_policies     = concat(module.baseline_presets.ec2_instance.config.default.instance_profile_policies, ["CSRWebServerPolicy"])
          user_data_raw                 = base64encode(file("./templates/user-data.yaml"))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["app", "domain", "jumpserver"]
          instance_type          = "t3.medium"
        })
        cloudwatch_metric_alarms = local.ec2_cloudwatch_metric_alarms.windows
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 192 } # minimum size has to be 128 due to snapshot sizes
        }
        tags = {
          description = "Test AWS AMI Windows Server 2022"
          os-type     = "Windows"
          component   = "appserver"
          server-type = "test-server"
        }
      }
    }

    baseline_ec2_autoscaling_groups = {}

    baseline_route53_zones = {
      "test.csr.service.justice.gov.uk" = {}
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

      csr-db-backup-bucket = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        iam_policies   = module.baseline_presets.s3_iam_policies
      }
    }
  }
}
