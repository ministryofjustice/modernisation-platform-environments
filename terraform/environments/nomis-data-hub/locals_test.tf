locals {

  baseline_presets_test = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          dso_pagerduty = "nomis_data_hub_nonprod_alarms"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_test = {

    iam_policies = {
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

    ec2_instances = {
      t1-ndh-app-a = merge(local.ndh_app_a, {
        config = merge(local.ndh_app_a.config, {
          instance_profile_policies = concat(local.ndh_app_a.config.instance_profile_policies, [
            "Ec2t1Policy",
          ])
        })
        tags = merge(local.ndh_app_a.tags, {
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
          nomis-data-hub-environment = "t2"
        })
      })

      test-management-server-2022 = merge(local.management_server_2022, {
        tags = merge(local.management_server_2022.tags, {
          nomis-data-hub-environment = "test"
        })
      })
    }

    #when changing the ems entries in prod or t2, also stop and start xtag to reconnect it.
    route53_zones = {
      "test.ndh.nomis.service.justice.gov.uk" = {
        records = [
          { name = "t1-app", type = "A", ttl = 300, records = ["10.26.8.54"] },
          { name = "t1-ems", type = "A", ttl = 300, records = ["10.26.8.49"] },
          { name = "t2-app", type = "A", ttl = 300, records = ["10.26.8.218"] },
          { name = "t2-ems", type = "A", ttl = 300, records = ["10.26.8.121"] },
        ]
      }
    }

    secretsmanager_secrets = {
      "/ndh/t1" = local.ndh_secretsmanager_secrets
      "/ndh/t2" = local.ndh_secretsmanager_secrets
    }
  }
}
