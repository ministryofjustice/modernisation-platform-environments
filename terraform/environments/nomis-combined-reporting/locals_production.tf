locals {

  baseline_presets_production = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          dso_pagerduty               = "nomis_alarms"
          dba_pagerduty               = "hmpps_shef_dba_low_priority"
          dba_high_priority_pagerduty = "hmpps_shef_dba_high_priority"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_production = {

    iam_policies = {
      Ec2PDDatabasePolicy = {
        description = "Permissions required for PROD Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "ssm:GetParameter",
            ]
            resources = [
              "arn:aws:ssm:*:*:parameter/azure/*",
            ]
          },
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
    }

    ec2_instances = {
      pd-ncr-db-1-a = merge(local.database_ec2_default, {
        cloudwatch_metric_alarms = merge(
          local.database_cloudwatch_metric_alarms.standard,
          local.database_cloudwatch_metric_alarms.db_connected,
          local.database_cloudwatch_metric_alarms.db_backup,
        )
        config = merge(local.database_ec2_default.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.database_ec2_default.config.instance_profile_policies, [
            "Ec2PDDatabasePolicy",
          ])
        })
        tags = merge(local.database_ec2_default.tags, {
          description                          = "PROD NCR DATABASE"
          nomis-combined-reporting-environment = "pd"
          oracle-sids                          = "PDBIPSYS PDBIPAUD"
          instance-scheduling                  = "skip-scheduling"
        })
      })

      pd-ncr-db-1-b = merge(local.database_ec2_default, {
        # TODO: comment in when commissioned
        # cloudwatch_metric_alarms = merge(
        #   local.database_cloudwatch_metric_alarms.standard,
        #   local.database_cloudwatch_metric_alarms.db_connected,
        # )
        config = merge(local.database_ec2_default.config, {
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.database_ec2_default.config.instance_profile_policies, [
            "Ec2PDDatabasePolicy",
          ])
        })
        tags = merge(local.database_ec2_default.tags, {
          description                          = "PROD NCR DATABASE"
          nomis-combined-reporting-environment = "pd"
          oracle-sids                          = ""
          instance-scheduling                  = "skip-scheduling"
        })
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
      "/oracle/database/PDBIPSYS" = local.database_secretsmanager_secrets
      "/oracle/database/PDBIPAUD" = local.database_secretsmanager_secrets
      "/oracle/database/PDBISYS"  = local.database_secretsmanager_secrets
      "/oracle/database/PDBIAUD"  = local.database_secretsmanager_secrets
    }
  }
}
