locals {

  baseline_presets_preproduction = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          dso_pagerduty = "nomis_data_hub_prod_alarms"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_preproduction = {

    ec2_instances = {
      pp-ndh-app-a = merge(local.ndh_app_a, {
        config = merge(local.ndh_app_a.config, {
          instance_profile_policies = concat(local.ndh_app_a.config.instance_profile_policies, [
            "Ec2ppPolicy",
          ])
        })
        tags = merge(local.ndh_app_a.tags, {
          nomis-data-hub-environment = "pp"
        })
      })

      pp-ndh-ems-a = merge(local.ndh_ems_a, {
        config = merge(local.ndh_ems_a.config, {
          instance_profile_policies = concat(local.ndh_ems_a.config.instance_profile_policies, [
            "Ec2ppPolicy",
          ])
        })
        tags = merge(local.ndh_ems_a.tags, {
          nomis-data-hub-environment = "pp"
        })
      })

      preprodution-management-server-2022 = merge(local.management_server_2022, {
        tags = merge(local.management_server_2022.tags, {
          nomis-data-hub-environment = "preprodution"
        })
      })
    }

    iam_policies = {
      Ec2ppPolicy = {
        description = "Permissions required for PP EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/ndh/pp/*",
            ]
          }
        ]
      }
    }

    #when changing the ems entries in preproduction, also stop and start xtag to reconnect it.
    route53_zones = {
      "preproduction.ndh.nomis.service.justice.gov.uk" = {
        records = [
          { name = "pp-app", type = "A", ttl = 300, records = ["10.27.0.196"] },
          { name = "pp-ems", type = "A", ttl = 300, records = ["10.27.0.119"] },
        ]
      }
    }
    secretsmanager_secrets = {
      "/ndh/pp" = local.ndh_secretsmanager_secrets
    }
  }
}
