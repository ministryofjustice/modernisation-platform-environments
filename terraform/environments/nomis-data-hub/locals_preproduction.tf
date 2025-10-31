locals {

  baseline_presets_preproduction = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "nomis-data-hub-preproduction"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_preproduction = {

    ec2_instances = {
      pp-ndh-app-a = merge(local.ec2_instances.ndh_app, {
        config = merge(local.ec2_instances.ndh_app.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.ndh_app.config.instance_profile_policies, [
            "Ec2ppPolicy",
          ])
        })
        instance = merge(local.ec2_instances.ndh_app.instance, {
          disable_api_termination = true
        })
        tags = merge(local.ec2_instances.ndh_app.tags, {
          nomis-data-hub-environment = "pp"
        })
      })

      pp-ndh-ems-a = merge(local.ec2_instances.ndh_ems, {
        config = merge(local.ec2_instances.ndh_ems.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.ndh_ems.config.instance_profile_policies, [
            "Ec2ppPolicy",
          ])
        })
        instance = merge(local.ec2_instances.ndh_ems.instance, {
          disable_api_termination = true
        })
        tags = merge(local.ec2_instances.ndh_ems.tags, {
          nomis-data-hub-environment = "pp"
        })
      })

      preprodution-management-server-2022 = merge(local.ec2_instances.ndh_mgmt, {
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

    patch_manager = {
      patch_schedules = {
        group1 = "cron(10 06 ? * WED *)" # 06:10 for non-prod env's as we have to work around the overnight shutdown  
      }
      maintenance_window_duration = 2
      maintenance_window_cutoff   = 1
      patch_classifications = {
        WINDOWS = ["SecurityUpdates", "CriticalUpdates"]
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
      "/ndh/pp" = local.secretsmanager_secrets.ndh
    }
  }
}
