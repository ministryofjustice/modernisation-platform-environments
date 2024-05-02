locals {
  production_config = {
    baseline_secretsmanager_secrets = {
      "/ndh/pd" = local.ndh_secretsmanager_secrets
    }
    baseline_iam_policies = {
      Ec2ppPolicy = {
        description = "Permissions required for PD EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/ndh/pd/*",
            ]
          }
        ]
      }
    }
    baseline_ec2_instances = {
      production-management-server-2022 = merge(local.management_server_2022, {
        tags = merge(local.management_server_2022.tags, {
          nomis-data-hub-environment = "production"
        })
      })
      pd-ndh-app-a = merge(local.ndh_app_a, {
        config = merge(local.ndh_app_a.config, {
          instance_profile_policies = concat(local.ndh_app_a.config.instance_profile_policies, [
            "Ec2ppPolicy",
          ])
        })
        tags = merge(local.ndh_app_a.tags, {
          os-type                    = "Linux"
          nomis-data-hub-environment = "pd"
        })
      })
      pd-ndh-ems-a = merge(local.ndh_ems_a, {
        config = merge(local.ndh_ems_a.config, {
          instance_profile_policies = concat(local.ndh_ems_a.config.instance_profile_policies, [
            "Ec2ppPolicy",
          ])
        })
        tags = merge(local.ndh_ems_a.tags, {
          os-type                    = "Linux"
          nomis-data-hub-environment = "pd"
        })
      })
      pd-ndh-app-b = merge(local.ndh_app_a, {
        config = merge(local.ndh_app_a.config, {
          instance_profile_policies = concat(local.ndh_app_a.config.instance_profile_policies, [
            "Ec2ppPolicy",
          ])
        })
        tags = merge(local.ndh_app_a.tags, {
          os-type                    = "Linux"
          nomis-data-hub-environment = "pd"
        })
      })
      pd-ndh-ems-b = merge(local.ndh_ems_a, {
        config = merge(local.ndh_ems_a.config, {
          instance_profile_policies = concat(local.ndh_ems_a.config.instance_profile_policies, [
            "Ec2ppPolicy",
          ])
        })
        tags = merge(local.ndh_ems_a.tags, {
          os-type                    = "Linux"
          nomis-data-hub-environment = "pd"
        })
      })
    }
    #when changing the ems entries in prod or t2, also stop and start xtag to reconnect it.
    baseline_route53_zones = {
      "ndh.nomis.service.justice.gov.uk" = {
        records = [
          { name = "preproduction", records = ["ns-1418.awsdns-49.org", "ns-230.awsdns-28.com", "ns-693.awsdns-22.net", "ns-1786.awsdns-31.co.uk"], type = "NS", ttl = "86400" },
          { name = "test", records = ["ns-498.awsdns-62.com", "ns-881.awsdns-46.net", "ns-1294.awsdns-33.org", "ns-1610.awsdns-09.co.uk"], type = "NS", ttl = "86400" },
          { name = "pd-app", type = "A", ttl = 300, records = ["10.40.3.196"] }, #azure
          #{ name = "pd-app", type = "A", ttl = 300, records = ["10.27.8.186"] }, #aws
          { name = "pd-ems", type = "A", ttl = 300, records = ["10.40.3.198"] }, #azure
          #{ name = "pd-ems", type = "A", ttl = 300, records = ["10.27.8.131"] }, #aws
        ]
      }
    }
  }
}
