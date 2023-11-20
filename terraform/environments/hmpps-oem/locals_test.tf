# nomis-test environment settings
locals {

  # baseline config
  test_config = {

    baseline_secretsmanager_secrets = {
      "/oracle/oem"              = local.oem_secretsmanager_secrets
      "/oracle/database/EMREP"   = local.oem_secretsmanager_secrets
      "/oracle/database/TRCVCAT" = local.oem_secretsmanager_secrets
    }

    baseline_ssm_parameters = {
      "/oracle/oem"              = local.oem_ssm_parameters_passwords
      "/oracle/database/EMREP"   = local.oem_ssm_parameters_passwords
      "/oracle/database/TRCVCAT" = local.oem_ssm_parameters_passwords
    }

    baseline_ec2_autoscaling_groups = {
      test-oem = merge(local.oem_ec2_default, {
        autoscaling_group = merge(local.oem_ec2_default.autoscaling_group, {
          desired_capacity = 0
        })
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
        tags = merge(local.oem_ec2_default.tags, {
          oracle-sids = "EMREP TRCVCAT"
        })
      })
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
