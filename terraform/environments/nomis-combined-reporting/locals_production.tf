locals {

  baseline_presets_production = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "nomis-combined-reporting-production"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_production = {

    acm_certificates = {
      nomis_combined_reporting_wildcard_cert = {
        cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name              = "modernisation-platform.service.justice.gov.uk"
        subject_alternate_names = [
          "reporting.nomis.service.justice.gov.uk",
          "*.reporting.nomis.service.justice.gov.uk",
        ]
        tags = {
          description = "Wildcard certificate for the production environment"
        }
      }
    }

    ec2_autoscaling_groups = {
      pd-ncr-app = merge(local.ec2_autoscaling_groups.bip_app, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.bip_app.autoscaling_group, {
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.bip_app.config, {
          instance_profile_policies = concat(local.ec2_autoscaling_groups.bip_app.config.instance_profile_policies, [
            "Ec2PDReportingPolicy",
          ])
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.bip_app.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.bip_app.user_data_cloud_init.args, {
            branch = "TM-913/align-ncr-and-onr-ansible"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.bip_app.tags, {
          nomis-combined-reporting-environment = "pd"
        })
      })

      pd-ncr-cms = merge(local.ec2_autoscaling_groups.bip_cms, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.bip_cms.autoscaling_group, {
          desired_capacity = 0
          max_size         = 2
        })
        config = merge(local.ec2_autoscaling_groups.bip_cms.config, {
          instance_profile_policies = concat(local.ec2_autoscaling_groups.bip_cms.config.instance_profile_policies, [
            "Ec2PDReportingPolicy",
          ])
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.bip_cms.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.bip_cms.user_data_cloud_init.args, {
            branch = "TM-913/align-ncr-and-onr-ansible"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.bip_cms.tags, {
          nomis-combined-reporting-environment = "pd"
        })
      })

      pd-ncr-webadmin = merge(local.ec2_autoscaling_groups.bip_webadmin, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.bip_webadmin.autoscaling_group, {
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.bip_webadmin.config, {
          instance_profile_policies = concat(local.ec2_autoscaling_groups.bip_webadmin.config.instance_profile_policies, [
            "Ec2PDReportingPolicy",
          ])
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.bip_webadmin.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.bip_webadmin.user_data_cloud_init.args, {
            branch = "TM-913/align-ncr-and-onr-ansible"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.bip_webadmin.tags, {
          nomis-combined-reporting-environment = "pd"
        })
      })

      pd-ncr-web = merge(local.ec2_autoscaling_groups.bip_web, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.bip_web.autoscaling_group, {
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.bip_web.config, {
          instance_profile_policies = concat(local.ec2_autoscaling_groups.bip_web.config.instance_profile_policies, [
            "Ec2PDReportingPolicy",
          ])
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.bip_web.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.bip_web.user_data_cloud_init.args, {
            branch = "TM-913/align-ncr-and-onr-ansible"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.bip_web.tags, {
          nomis-combined-reporting-environment = "pd"
        })
      })
    }


    ec2_instances = {

      pd-ncr-db-1-a = merge(local.ec2_instances.db, {
        cloudwatch_metric_alarms = merge(
          local.cloudwatch_metric_alarms.db,
          local.cloudwatch_metric_alarms.db_connected,
          local.cloudwatch_metric_alarms.db_backup,
        )
        config = merge(local.ec2_instances.db.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2PDDatabasePolicy",
          ])
        })
        ebs_volumes = {
          "/dev/sdb" = { type = "gp3", label = "app", size = 100 }   # /u01
          "/dev/sdc" = { type = "gp3", label = "app", size = 500 }   # /u02
          "/dev/sde" = { type = "gp3", label = "data", size = 500 }  # DATA01
          "/dev/sdj" = { type = "gp3", label = "flash", size = 250 } # FLASH01
          "/dev/sds" = { type = "gp3", label = "swap", size = 4 }
        }
        tags = merge(local.ec2_instances.db.tags, {
          description                          = "PROD NCR DATABASE"
          nomis-combined-reporting-environment = "pd"
          oracle-sids                          = "PDBIPSYS PDBIPAUD"
        })
      })

      pd-ncr-db-1-b = merge(local.ec2_instances.db, {
        cloudwatch_metric_alarms = merge(
          local.cloudwatch_metric_alarms.db,
          local.cloudwatch_metric_alarms.db_connected,
        )
        config = merge(local.ec2_instances.db.config, {
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2PDDatabasePolicy",
          ])
        })
        tags = merge(local.ec2_instances.db.tags, {
          description                          = "PROD NCR DATABASE"
          nomis-combined-reporting-environment = "pd"
          oracle-sids                          = "DRBIPSYS DRBIPAUD"
        })
      })
    }

    # Comment out till needed for deployment
    efs = {
      pd-ncr-sap-share = local.efs.sap_share
    }

    iam_policies = {
      Ec2PDDatabasePolicy = {
        description = "Permissions required for PROD Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PD/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PD*/*",
            ]
          }
        ]
      }
      Ec2PDReportingPolicy = {
        description = "Permissions required for PD reporting EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/sap/bip/pd/*",
              "arn:aws:secretsmanager:*:*:secret:/sap/bods/pd/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PD/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PD*/*",
            ]
          },
          {
            effect = "Allow"
            actions = [
              "elasticloadbalancing:Describe*",
            ]
            resources = ["*"]
          },
          {
            effect = "Allow"
            actions = [
              "elasticloadbalancing:SetRulePriorities",
            ]
            resources = [
              "arn:aws:elasticloadbalancing:*:*:listener-rule/app/private-lb/*",
              "arn:aws:elasticloadbalancing:*:*:listener-rule/app/public-lb/*",
            ]
          }
        ]
      }
    }

    lbs = {
      private = merge(local.lbs.private, {
      })
    }

    route53_zones = {
      "reporting.nomis.service.justice.gov.uk" = {
        ns_records = [
          # use this if NS records can be pulled from terrafrom, otherwise use records variable
          { name = "production", ttl = "86400", zone_name = "production.reporting.nomis.service.justice.gov.uk" }
        ]
        records = [
          { name = "development", type = "NS", ttl = "86400", records = ["ns-104.awsdns-13.com", "ns-1357.awsdns-41.org", "ns-1718.awsdns-22.co.uk", "ns-812.awsdns-37.net"] },
          { name = "test", type = "NS", ttl = "86400", records = ["ns-1011.awsdns-62.net", "ns-1090.awsdns-08.org", "ns-1938.awsdns-50.co.uk", "ns-390.awsdns-48.com"] },
          { name = "preproduction", type = "NS", ttl = "86400", records = ["ns-1525.awsdns-62.org", "ns-1563.awsdns-03.co.uk", "ns-38.awsdns-04.com", "ns-555.awsdns-05.net"] },
          { name = "lsast", type = "NS", ttl = "86400", records = ["ns-1285.awsdns-32.org", "ns-1780.awsdns-30.co.uk", "ns-198.awsdns-24.com", "ns-852.awsdns-42.net"] },
          { name = "db-a", type = "CNAME", ttl = "300", records = ["pd-ncr-db-1-a.nomis-combined-reporting.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "db-b", type = "CNAME", ttl = "300", records = ["pd-ncr-db-1-b.nomis-combined-reporting.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
        ]
      }

      "production.reporting.nomis.service.justice.gov.uk" = {
      }
    }

    secretsmanager_secrets = {
      "/oracle/database/PDBIPSYS" = local.secretsmanager_secrets.db # Azure Live System DB
      "/oracle/database/PDBIPAUD" = local.secretsmanager_secrets.db # Azure Live Audit DB
      "/oracle/database/PDBISYS"  = local.secretsmanager_secrets.db
      "/oracle/database/PDBIAUD"  = local.secretsmanager_secrets.db
      "/sap/bip/pd"               = local.secretsmanager_secrets.bip
      "/sap/bods/pd"              = local.secretsmanager_secrets.bods
    }
  }
}
