locals {
  production_config = {

    baseline_s3_buckets = {
      ncr-db-backup-bucket = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.ProdPreprodEnvironmentsReadOnlyAccessBucketPolicy,
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
      }
    }

    baseline_secretsmanager_secrets = {
      "/oracle/database/PDBIPSYS" = local.database_secretsmanager_secrets
      "/oracle/database/PDBIPAUD" = local.database_secretsmanager_secrets
      "/oracle/database/PDBISYS"  = local.database_secretsmanager_secrets
      "/oracle/database/PDBIAUD"  = local.database_secretsmanager_secrets
    }

    baseline_iam_policies = {
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

    baseline_ec2_instances = {
      pd-ncr-db-1-a = merge(local.database_ec2_default, {
        config = merge(local.database_ec2_default.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.database_ec2_default.config.instance_profile_policies, [
            "Ec2PDDatabasePolicy",
          ])
        })
        ebs_volumes = {
          "/dev/sdb" = { # /u01
            size  = 100
            label = "app"
            type  = "gp3"
          }
          "/dev/sdc" = { # /u02
            size  = 500
            label = "app"
            type  = "gp3"
          }
          "/dev/sde" = { # DATA01
            label = "data"
            size  = 500
            type  = "gp3"
          }
          "/dev/sdj" = { # FLASH01
            label = "flash"
            type  = "gp3"
            size  = 200
          }
          "/dev/sds" = {
            label = "swap"
            type  = "gp3"
            size  = 4
          }
        }
        ebs_volume_config = {
          data = {
            iops       = 3000 # min 3000
            type       = "gp3"
            throughput = 125
            total_size = 500
          }
          flash = {
            iops       = 3000 # min 3000
            type       = "gp3"
            throughput = 125
            total_size = 200
          }
        }
        tags = merge(local.database_ec2_default.tags, {
          description                          = "PROD NCR DATABASE"
          nomis-combined-reporting-environment = "pd"
          oracle-sids                          = ""
          instance-scheduling                  = "skip-scheduling"
        })
      })
      pd-ncr-db-1-b = merge(local.database_ec2_default, {
        availability_zone = "eu-west-2b"
        config = merge(local.database_ec2_default.config, {
          instance_profile_policies = concat(local.database_ec2_default.config.instance_profile_policies, [
            "Ec2PDDatabasePolicy",
          ])
        })
        ebs_volumes = {
          "/dev/sdb" = { # /u01
            size  = 100
            label = "app"
            type  = "gp3"
          }
          "/dev/sdc" = { # /u02
            size  = 500
            label = "app"
            type  = "gp3"
          }
          "/dev/sde" = { # DATA01
            label = "data"
            size  = 500
            type  = "gp3"
          }
          "/dev/sdj" = { # FLASH01
            label = "flash"
            type  = "gp3"
            size  = 200
          }
          "/dev/sds" = {
            label = "swap"
            type  = "gp3"
            size  = 4
          }
        }
        ebs_volume_config = {
          data = {
            iops       = 3000 # min 3000
            type       = "gp3"
            throughput = 125
            total_size = 500
          }
          flash = {
            iops       = 3000 # min 3000
            type       = "gp3"
            throughput = 125
            total_size = 200
          }
        }
        tags = merge(local.database_ec2_default.tags, {
          description                          = "PROD NCR DATABASE"
          nomis-combined-reporting-environment = "pd"
          oracle-sids                          = ""
          instance-scheduling                  = "skip-scheduling"
        })
      })
    }

    baseline_route53_zones = {
      "reporting.nomis.service.justice.gov.uk" = {
        ns_records = [
          # use this if NS records can be pulled from terrafrom, otherwise use records variable
          { name = "production", ttl = "86400", zone_name = "production.reporting.nomis.service.justice.gov.uk" }
        ]
        records = [
          { name = "development", type = "NS", ttl = "86400", records = ["ns-104.awsdns-13.com", "ns-1357.awsdns-41.org", "ns-1718.awsdns-22.co.uk", "ns-812.awsdns-37.net"] },
          { name = "test", type = "NS", ttl = "86400", records = ["ns-1011.awsdns-62.net", "ns-1090.awsdns-08.org", "ns-1938.awsdns-50.co.uk", "ns-390.awsdns-48.com"] },
          { name = "preproduction", type = "NS", ttl = "86400", records = ["ns-1525.awsdns-62.org", "ns-1563.awsdns-03.co.uk", "ns-38.awsdns-04.com", "ns-555.awsdns-05.net"] },
        ]
      }
      "production.reporting.nomis.service.justice.gov.uk" = {
      }

    }

  }
}
