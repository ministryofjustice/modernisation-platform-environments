locals {

  baseline_presets_test = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "nomis-data-hub-test"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_test = {

    ec2_instances = {
      t1-ndh-app-a = merge(local.ec2_instances.ndh_app, {
        config = merge(local.ec2_instances.ndh_app.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.ndh_app.config.instance_profile_policies, [
            "Ec2t1Policy",
          ])
        })
        instance = merge(local.ec2_instances.ndh_app.instance, {
          disable_api_termination = true
        })
        tags = merge(local.ec2_instances.ndh_app.tags, {
          nomis-data-hub-environment = "t1"
        })
      })

      t1-ndh-ems-a = merge(local.ec2_instances.ndh_ems, {
        config = merge(local.ec2_instances.ndh_ems.config, {
          ami_name          = "nomis_data_hub_rhel_7_9_ems_test_2023-04-02T00-00-21.281Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.ndh_ems.config.instance_profile_policies, [
            "Ec2t1Policy",
          ])
        })
        instance = merge(local.ec2_instances.ndh_ems.instance, {
          disable_api_termination = true
        })
        tags = merge(local.ec2_instances.ndh_ems.tags, {
          nomis-data-hub-environment = "t1"
        })
      })

      t2-ndh-app-a = merge(local.ec2_instances.ndh_app, {
        config = merge(local.ec2_instances.ndh_app.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.ndh_app.config.instance_profile_policies, [
            "Ec2t2Policy",
          ])
        })
        instance = merge(local.ec2_instances.ndh_app.instance, {
          disable_api_termination = true
        })
        tags = merge(local.ec2_instances.ndh_app.tags, {
          nomis-data-hub-environment = "t2"
        })
      })

      t2-ndh-ems-a = merge(local.ec2_instances.ndh_ems, {
        config = merge(local.ec2_instances.ndh_ems.config, {
          ami_name          = "nomis_data_hub_rhel_7_9_ems_test_2023-04-02T00-00-21.281Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.ndh_ems.config.instance_profile_policies, [
            "Ec2t2Policy",
          ])
        })
        instance = merge(local.ec2_instances.ndh_ems.instance, {
          disable_api_termination = true
        })
        tags = merge(local.ec2_instances.ndh_ems.tags, {
          nomis-data-hub-environment = "t2"
        })
      })

      test-management-server-2022 = merge(local.ec2_instances.ndh_mgmt, {
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
          nomis-data-hub-environment = "test"
        })
      })
    }

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

    patch_manager = {
      patch_schedules = {
        group1 = "cron(10 06 ? * TUE *)" # 06:10 for non-prod env's as we have to work around the overnight shutdown  
      }
      maintenance_window_duration = 2
      maintenance_window_cutoff   = 1
      patch_classifications = {
        WINDOWS = ["SecurityUpdates", "CriticalUpdates"]
      }
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
      "/ndh/t1" = local.secretsmanager_secrets.ndh
      "/ndh/t2" = local.secretsmanager_secrets.ndh
    }
  }
}
