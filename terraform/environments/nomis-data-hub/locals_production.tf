locals {
  baseline_presets_production = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "nomis-data-hub-production"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_production = {

    ec2_instances = {
      dr-ndh-app-b = merge(local.ec2_instances.ndh_app, {
        cloudwatch_metric_alarms = merge(
          local.ec2_instances.ndh_app.cloudwatch_metric_alarms,
        )
        config = merge(local.ec2_instances.ndh_app.config, {
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.ndh_app.config.instance_profile_policies, [
            "Ec2pdPolicy",
          ])
        })
        instance = merge(local.ec2_instances.ndh_app.instance, {
          disable_api_termination = true
        })
        tags = merge(local.ec2_instances.ndh_app.tags, {
          nomis-data-hub-environment = "dr"
        })
      })

      dr-ndh-ems-b = merge(local.ec2_instances.ndh_ems, {
        config = merge(local.ec2_instances.ndh_ems.config, {
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.ndh_ems.config.instance_profile_policies, [
            "Ec2pdPolicy",
          ])
        })
        instance = merge(local.ec2_instances.ndh_ems.instance, {
          disable_api_termination = true
        })
        tags = merge(local.ec2_instances.ndh_ems.tags, {
          nomis-data-hub-environment = "dr"
        })
      })

      pd-ndh-app-a = merge(local.ec2_instances.ndh_app, {
        cloudwatch_metric_alarms = merge(
          local.ec2_instances.ndh_app.cloudwatch_metric_alarms,
        )
        config = merge(local.ec2_instances.ndh_app.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.ndh_app.config.instance_profile_policies, [
            "Ec2pdPolicy",
          ])
        })
        instance = merge(local.ec2_instances.ndh_app.instance, {
          disable_api_termination = true
        })
        tags = merge(local.ec2_instances.ndh_app.tags, {
          nomis-data-hub-environment = "pd"
        })
      })

      pd-ndh-ems-a = merge(local.ec2_instances.ndh_ems, {
        config = merge(local.ec2_instances.ndh_ems.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.ndh_ems.config.instance_profile_policies, [
            "Ec2pdPolicy",
          ])
        })
        instance = merge(local.ec2_instances.ndh_ems.instance, {
          disable_api_termination = true
        })
        tags = merge(local.ec2_instances.ndh_ems.tags, {
          nomis-data-hub-environment = "pd"
        })
      })

      production-management-server-2022 = merge(local.ec2_instances.ndh_mgmt, {
        config = merge(local.ec2_instances.ndh_mgmt.config, {
          ami_name          = "hmpps_windows_server_2022_release_2023-12-02T00-00-15.711Z"
          availability_zone = "eu-west-2a"
        })
        instance = merge(local.ec2_instances.ndh_mgmt.instance, {
          disable_api_termination = true
          tags = merge(local.ec2_instances.ndh_mgmt.instance.tags, {
            patch-manager = "group1"
          })
        })
        tags = merge(local.ec2_instances.ndh_mgmt.tags, {
          nomis-data-hub-environment = "production"
        })
      })
    }

    iam_policies = {
      Ec2pdPolicy = {
        description = "Permissions required for PD EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/ndh/pd/*",
              "arn:aws:secretsmanager:*:*:secret:/ndh/dr/*",
            ]
          }
        ]
      }
    }

    patch_manager = {
      patch_schedules = {
        group1 = "cron(00 03 ? * THU *)"  
      }
      maintenance_window_duration = 4
      maintenance_window_cutoff   = 2
      patch_classifications = {
        WINDOWS = ["SecurityUpdates", "CriticalUpdates"]
      }
    }

    #when changing the ems entries in prod or t2, also stop and start xtag to reconnect it.
    route53_zones = {
      "ndh.nomis.service.justice.gov.uk" = {
        records = [
          { name = "preproduction", records = ["ns-1418.awsdns-49.org", "ns-230.awsdns-28.com", "ns-693.awsdns-22.net", "ns-1786.awsdns-31.co.uk"], type = "NS", ttl = "86400" },
          { name = "test", records = ["ns-498.awsdns-62.com", "ns-881.awsdns-46.net", "ns-1294.awsdns-33.org", "ns-1610.awsdns-09.co.uk"], type = "NS", ttl = "86400" },
          { name = "pd-app", type = "A", ttl = 300, records = ["10.27.8.136"] }, #aws pd
          #{ name = "pd-app", type = "A", ttl = 300, records = ["10.27.9.33"] }, #aws dr
          { name = "pd-ems", type = "A", ttl = 300, records = ["10.27.8.120"] }, #aws pd
          #{ name = "pd-ems", type = "A", ttl = 300, records = ["10.27.9.228"] }, #aws dr
        ]
      }
    }

    secretsmanager_secrets = {
      "/ndh/pd" = local.secretsmanager_secrets.ndh
      "/ndh/dr" = local.secretsmanager_secrets.ndh
    }
  }
}
