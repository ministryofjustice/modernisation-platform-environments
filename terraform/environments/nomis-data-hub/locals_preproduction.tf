locals {
  preproduction_config = {
    baseline_secretsmanager_secrets = {
      "/ndh/pp" = local.ndh_secretsmanager_secrets
    }

    baseline_iam_policies = {
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

    baseline_ec2_instances = {

      preprodution-management-server-2022 = merge(local.management_server_2022, {
        tags = merge(local.management_server_2022.tags, {
          nomis-data-hub-environment = "preprodution"
        })
      })

      pp-ndh-app-a = merge(local.ndh_app_a, {
        config = merge(local.ndh_app_a.config, {
          instance_profile_policies = concat(local.ndh_app_a.config.instance_profile_policies, [
            "Ec2ppPolicy",
          ])
        })
        tags = merge(local.ndh_app_a.tags, {
          os-type                    = "Linux"
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
          os-type                    = "Linux"
          nomis-data-hub-environment = "pp"
        })
      })
    }

    #when changing the ems entries in preproduction, also stop and start xtag to reconnect it.
    baseline_route53_zones = {
      "preproduction.ndh.nomis.service.justice.gov.uk" = {
        records = [
          #{ name = "pp-app", type = "A", ttl = 300, records = ["10.40.37.197"] }, #azure
          { name = "pp-app", type = "A", ttl = 300, records = ["10.27.0.196"] }, #aws
          #{ name = "pp-ems", type = "A", ttl = 300, records = ["10.40.37.199"] }, #azure
          { name = "pp-ems", type = "A", ttl = 300, records = ["10.27.0.119"] }, #aws
        ]
      }
    }
  }
}
