locals {
  baseline_presets_production = {
    options = {
      cloudwatch_dashboard_default_widget_groups = [
        "ec2",
        "ec2_linux",
        "ec2_instance_linux",
        "ec2_instance_filesystems",
      ]
      sns_topics = {
        pagerduty_integrations = {
          dso_pagerduty = "nomis_data_hub_prod_alarms"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_production = {

    ec2_instances = {
      dr-ndh-app-b = merge(local.ndh_app_a, {
        cloudwatch_metric_alarms = merge(
          local.ndh_app_a.cloudwatch_metric_alarms,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_filesystems_check
        )
        config = merge(local.ndh_app_a.config, {
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ndh_app_a.config.instance_profile_policies, [
            "Ec2pdPolicy",
          ])
        })
        tags = merge(local.ndh_app_a.tags, {
          nomis-data-hub-environment = "dr"
        })
      })

      dr-ndh-ems-b = merge(local.ndh_ems_a, {
        config = merge(local.ndh_ems_a.config, {
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ndh_ems_a.config.instance_profile_policies, [
            "Ec2pdPolicy",
          ])
        })
        tags = merge(local.ndh_ems_a.tags, {
          nomis-data-hub-environment = "dr"
        })
      })

      pd-ndh-app-a = merge(local.ndh_app_a, {
        cloudwatch_metric_alarms = merge(
          local.ndh_app_a.cloudwatch_metric_alarms,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_filesystems_check
        )
        config = merge(local.ndh_app_a.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ndh_app_a.config.instance_profile_policies, [
            "Ec2pdPolicy",
          ])
        })
        tags = merge(local.ndh_app_a.tags, {
          nomis-data-hub-environment = "pd"
        })
      })

      pd-ndh-ems-a = merge(local.ndh_ems_a, {
        config = merge(local.ndh_ems_a.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ndh_ems_a.config.instance_profile_policies, [
            "Ec2pdPolicy",
          ])
        })
        tags = merge(local.ndh_ems_a.tags, {
          nomis-data-hub-environment = "pd"
        })
      })

      production-management-server-2022 = merge(local.management_server_2022, {
        tags = merge(local.management_server_2022.tags, {
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

    #when changing the ems entries in prod or t2, also stop and start xtag to reconnect it.
    route53_zones = {
      "ndh.nomis.service.justice.gov.uk" = {
        records = [
          { name = "preproduction", records = ["ns-1418.awsdns-49.org", "ns-230.awsdns-28.com", "ns-693.awsdns-22.net", "ns-1786.awsdns-31.co.uk"], type = "NS", ttl = "86400" },
          { name = "test", records = ["ns-498.awsdns-62.com", "ns-881.awsdns-46.net", "ns-1294.awsdns-33.org", "ns-1610.awsdns-09.co.uk"], type = "NS", ttl = "86400" },
          #{ name = "pd-app", type = "A", ttl = 300, records = ["10.40.3.196"] }, #azure
          { name = "pd-app", type = "A", ttl = 300, records = ["10.27.8.136"] }, #aws pd
          #{ name = "pd-app", type = "A", ttl = 300, records = ["10.27.9.33"] }, #aws dr
          #{ name = "pd-ems", type = "A", ttl = 300, records = ["10.40.3.198"] }, #azure
          { name = "pd-ems", type = "A", ttl = 300, records = ["10.27.8.120"] }, #aws pd
          #{ name = "pd-ems", type = "A", ttl = 300, records = ["10.27.9.228"] }, #aws dr
        ]
      }
    }

    s3_buckets = {
      offloc-upload = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy,
        ]
        iam_policies   = module.baseline_presets.s3_iam_policies
        lifecycle_rule = [module.baseline_presets.s3_lifecycle_rules.general_purpose_three_months]
        tags = {
          backup = "false"
        }
      }
    }

    secretsmanager_secrets = {
      "/ndh/pd" = local.ndh_secretsmanager_secrets
      "/ndh/dr" = local.ndh_secretsmanager_secrets
    }

    ssm_parameters = {
      "/offloc" = {
        parameters = {
          offloc_bucket_name = {
            description          = "The name of the offloc upload bucket"
            value_s3_bucket_name = "offloc-upload"
          }
        }
      }
    }
  }
}
