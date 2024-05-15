locals {
  test_config = {

    baseline_secretsmanager_secrets = {
      "/ndh/t1" = local.ndh_secretsmanager_secrets
      "/ndh/t2" = local.ndh_secretsmanager_secrets
    }

    baseline_iam_policies = {
      Ec2t1Policy = {
        description = "Permissions required for t1 EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/ndh/t1/*",
            ]
          }
        ]
      }

      Ec2t2Policy = {
        description = "Permissions required for t2 EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/ndh/t2/*",
            ]
          }
        ]
      }
    }

    baseline_ec2_instances = {

      test-management-server-2022 = merge(local.management_server_2022, {
        tags = merge(local.management_server_2022.tags, {
          nomis-data-hub-environment = "test"
        })
      })

      t1-ndh-app-a = merge(local.ndh_app_a, {
        config = merge(local.ndh_app_a.config, {
          instance_profile_policies = concat(local.ndh_app_a.config.instance_profile_policies, [
            "Ec2t1Policy",
          ])
        })
        tags = merge(local.ndh_app_a.tags, {
          os-type                    = "Linux"
          nomis-data-hub-environment = "t1"
        })
      })

      t1-ndh-ems-a = merge(local.ndh_ems_a, {
        config = merge(local.ndh_ems_a.config, {
          ami_name = "nomis_data_hub_rhel_7_9_ems_test_2023-04-02T00-00-21.281Z"
          instance_profile_policies = concat(local.ndh_ems_a.config.instance_profile_policies, [
            "Ec2t1Policy",
          ])
        })
        tags = merge(local.ndh_ems_a.tags, {
          os-type                    = "Linux"
          nomis-data-hub-environment = "t1"
        })
      })

      t2-ndh-app-a = merge(local.ndh_app_a, {
        config = merge(local.ndh_app_a.config, {
          instance_profile_policies = concat(local.ndh_app_a.config.instance_profile_policies, [
            "Ec2t2Policy",
          ])
        })
        tags = merge(local.ndh_app_a.tags, {
          os-type                    = "Linux"
          nomis-data-hub-environment = "t2"
        })
      })

      t2-ndh-ems-a = merge(local.ndh_ems_a, {
        config = merge(local.ndh_ems_a.config, {
          ami_name = "nomis_data_hub_rhel_7_9_ems_test_2023-04-02T00-00-21.281Z"
          instance_profile_policies = concat(local.ndh_ems_a.config.instance_profile_policies, [
            "Ec2t2Policy",
          ])
        })
        tags = merge(local.ndh_ems_a.tags, {
          os-type                    = "Linux"
          nomis-data-hub-environment = "t2"
        })
      })
    }

    baseline_ssm_parameters = {
      "/offloc" = {
        parameters = {
          offloc_bucket_name = {
            description = "The name of the offloc upload bucket"
            value_s3_bucket_name = "offloc-upload"
          }
        }
      }
    }


    baseline_s3_buckets = {

      offloc-upload = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy,
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
      }

      # the shared image builder bucket is just created in one account
      nomis-data-hub-software = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
          module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy,
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
      }
    }

    #when changing the ems entries in prod or t2, also stop and start xtag to reconnect it.
    baseline_route53_zones = {
      "test.ndh.nomis.service.justice.gov.uk" = {
        records = [
          #{ name = "t1-app", type = "A", ttl = 300, records = ["10.101.3.196"] }, #azure
          { name = "t1-app", type = "A", ttl = 300, records = ["10.26.8.54"] }, #aws
          #{ name = "t1-ems", type = "A", ttl = 300, records = ["10.101.3.197"] }, #azure
          { name = "t1-ems", type = "A", ttl = 300, records = ["10.26.8.49"] }, #aws
          #{ name = "t2-app", type = "A", ttl = 300, records = ["10.101.33.196"] }, #azure
          { name = "t2-app", type = "A", ttl = 300, records = ["10.26.8.218"] }, #aws
          #{ name = "t2-ems", type = "A", ttl = 300, records = ["10.101.33.197"] }, #azure
          { name = "t2-ems", type = "A", ttl = 300, records = ["10.26.8.121"] }, #aws
        ]
      }
    }
  }
}
