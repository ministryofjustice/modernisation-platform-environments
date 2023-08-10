# nomis-test environment settings
locals {

  # baseline config
  test_config = {

    baseline_ssm_parameters = {
      "test-oem/TRCVCAT" = local.oem_database_instance_ssm_parameters
      "test-oem/EMREP"   = local.oem_emrep_ssm_parameters
      "test-oem/OEM"     = local.oem_ssm_parameters
      "oem-a/TRCVCAT"    = local.oem_database_instance_ssm_parameters
      "oem-a/EMREP"      = local.oem_emrep_ssm_parameters
      "oem-a/OEM"        = local.oem_ssm_parameters
      "oem-b/TRCVCAT"    = local.oem_database_instance_ssm_parameters
      "oem-b/EMREP"      = local.oem_emrep_ssm_parameters
      "oem-b/OEM"        = local.oem_ssm_parameters
    }

    baseline_ec2_autoscaling_groups = {
      test-oem = merge(local.oem_ec2_default, {
        user_data_cloud_init = merge(local.oem_ec2_default.user_data_cloud_init, {
          args = merge(local.oem_ec2_default.user_data_cloud_init.args, {
            branch = "main"
          })
        })
      })
    }

    baseline_ec2_instances = {
      #      oem-a = merge(local.oem_ec2_default, {
      #        config = merge(local.oem_ec2_default.config, {
      #          availability_zone = "eu-west-2a"
      #        })
      #        user_data_cloud_init = merge(local.oem_ec2_default.user_data_cloud_init, {
      #          args = merge(local.oem_ec2_default.user_data_cloud_init.args, {
      #            branch = "main"
      #          })
      #        })
      #      })
      #      oem-b = merge(local.oem_ec2_default, {
      #        config = merge(local.oem_ec2_default.config, {
      #          availability_zone = "eu-west-2a"
      #        })
      #        user_data_cloud_init = merge(local.oem_ec2_default.user_data_cloud_init, {
      #          args = merge(local.oem_ec2_default.user_data_cloud_init.args, {
      #            branch = "nomis/DSOS-2088/standalone-ec2-instance-for-oem"
      #          })
      #        })
      #      })
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
          { name = "oem.hmpps-oem", type = "CNAME", ttl = "300", records = ["oem-a.hmpps-oem.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
        ]
      }
    }
  }
}
