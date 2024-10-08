locals {

  baseline_presets_test = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "nomis-combined-reporting-test"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_test = {

    ec2_instances = {
      t1-ncr-db-1-a = merge(local.ec2_instances.db, {
        cloudwatch_metric_alarms = merge(
          local.cloudwatch_metric_alarms.db,
          local.cloudwatch_metric_alarms.db_connected,
          local.cloudwatch_metric_alarms.db_backup,
        )
        config = merge(local.ec2_instances.db.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2T1DatabasePolicy",
          ])
        })
        ebs_volumes = {
          "/dev/sdb" = { type = "gp3", label = "app", size = 100 }  # /u01
          "/dev/sdc" = { type = "gp3", label = "app", size = 100 }  # /u02
          "/dev/sde" = { type = "gp3", label = "data", size = 100 } # DATA01
          "/dev/sdf" = { type = "gp3", label = "data", size = 100 } # DATA02
          "/dev/sdg" = { type = "gp3", label = "data", size = 100 } # DATA03
          "/dev/sdh" = { type = "gp3", label = "data", size = 100 } # DATA04
          "/dev/sdi" = { type = "gp3", label = "data", size = 100 } # DATA05
          "/dev/sdj" = { type = "gp3", label = "flash", size = 25 } # FLASH01
          "/dev/sdk" = { type = "gp3", label = "flash", size = 25 } # FLASH02
          "/dev/sds" = { type = "gp3", label = "swap", size = 16 }
        }
        tags = merge(local.ec2_instances.db.tags, {
          description                          = "T1 NCR DATABASE"
          nomis-combined-reporting-environment = "t1"
          oracle-sids                          = "T1BIPSYS T1BIPAUD"
          instance-scheduling                  = "skip-scheduling"
        })
      })
    }

    iam_policies = {
      Ec2T1DatabasePolicy = {
        description = "Permissions required for T1 Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*T1/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T1*/*",
            ]
          }
        ]
      }

      Ec2T1ReportingPolicy = {
        description = "Permissions required for T1 reporting EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/sap/bip/t1/*",
              "arn:aws:secretsmanager:*:*:secret:/sap/bods/t1/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*T1/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T1*/*",
            ]
          }
        ]
      }
    }

    lbs = {
      private = merge(local.lbs.private, {
        instance_target_groups = {}
        listeners              = {}
      })
    }

    route53_zones = {
      "test.reporting.nomis.service.justice.gov.uk" = {
        records = [
          { name = "db", type = "CNAME", ttl = "3600", records = ["t1-ncr-db-1-a.nomis-combined-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "web", type = "CNAME", ttl = "3600", records = ["t1-ncr-web-1-a.nomis-combined-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "etl", type = "CNAME", ttl = "3600", records = ["t1-ncr-etl-1-a.nomis-combined-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk"] }
        ]
      }
    }

    s3_buckets = {
      nomis-combined-reporting-bip-packages = {
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.AllEnvironmentsReadOnlyAccessBucketPolicy
        ]
        custom_kms_key = module.environment.kms_keys["general"].arn
        iam_policies   = module.baseline_presets.s3_iam_policies
        lifecycle_rule = [module.baseline_presets.s3_lifecycle_rules.software]
        tags = {
          backup = "false"
        }
      }
    }

    secretsmanager_secrets = {
      "/oracle/database/T1BIPSYS" = local.secretsmanager_secrets.db
      "/oracle/database/T1BIPAUD" = local.secretsmanager_secrets.db
      "/sap/bip/t1"               = local.secretsmanager_secrets.bip
      "/sap/bods/t1"              = local.secretsmanager_secrets.bods
    }
  }
}
