# nomis-test environment settings
locals {

  # baseline config
  test_config = {

    baseline_ssm_parameters = {
      "test-oem/TRCVCAT"   = local.oem_database_instance_ssm_parameters
      "test-oem/EMREP"     = local.oem_emrep_ssm_parameters
      "test-oem/OEM"       = local.oem_ssm_parameters
      "test-oem-a/TRCVCAT" = local.oem_database_instance_ssm_parameters
      "test-oem-a/EMREP"   = local.oem_emrep_ssm_parameters
      "test-oem-a/OEM"     = local.oem_ssm_parameters
      "test-oem-b/TRCVCAT" = local.oem_database_instance_ssm_parameters
      "test-oem-b/EMREP"   = local.oem_emrep_ssm_parameters
      "test-oem-b/OEM"     = local.oem_ssm_parameters
    }

    baseline_ec2_autoscaling_groups = {
      test-oem = merge(local.oem_ec2_default, {
        user_data_cloud_init = merge(local.oem_ec2_default.user_data_cloud_init, {
          args = merge(local.oem_ec2_default.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.oem_ec2_default.tags, {
            oracle-sids = "EMREP TRCVCAT"
        })
      })
    }

    baseline_ec2_instances = {
      test-oem-a = merge(local.oem_ec2_default, {
        config = merge(local.oem_ec2_default.config, {
          availability_zone = "eu-west-2a"
        })
        user_data_cloud_init = merge(local.oem_ec2_default.user_data_cloud_init, {
          args = merge(local.oem_ec2_default.user_data_cloud_init.args, {
            branch = "45027fb7482eb7fb601c9493513bb73658780dda" # 2023-08-11
          })
        })
      })
      # test-oem-b = merge(local.oem_ec2_default, {
      #   config = merge(local.oem_ec2_default.config, {
      #     availability_zone = "eu-west-2b"
      #   })
      #   user_data_cloud_init = merge(local.oem_ec2_default.user_data_cloud_init, {
      #     args = merge(local.oem_ec2_default.user_data_cloud_init.args, {
      #       branch = "main"
      #     })
      #   })
      # })
    }

    baseline_s3_buckets = {
      # use this bucket for storing artefacts for use across all accounts
      hmpps-oem-software = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
          module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy,
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
      }
    }

    baseline_route53_zones = {
      "hmpps-test.modernisation-platform.service.justice.gov.uk" = {
        records = [
          { name = "oem.hmpps-oem", type = "CNAME", ttl = "300", records = ["test-oem-a.hmpps-oem.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
        ]
      }
    }
  }
}
