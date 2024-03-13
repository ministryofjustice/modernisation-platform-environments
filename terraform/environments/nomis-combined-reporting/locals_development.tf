locals {
  development_config = {
    baseline_s3_buckets = {
      ncr-db-backup-bucket = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        iam_policies   = module.baseline_presets.s3_iam_policies
      }
    }
    baseline_iam_policies = {
      Ec2DevDatabasePolicy = {
        description = "Permissions required for DEV Database EC2s"
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
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*DEV/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/DEV*/*",
            ]
          }
        ]
      }
      Ec2DevReportingPolicy = {
        description = "Permissions required for DEV reporting EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/ec2/ncr-bip-cms/dev/*",
              "arn:aws:secretsmanager:*:*:secret:/ec2/ncr-tomcat-admin/dev/*",
            ]
          }
        ]
      }
    }
    baseline_ec2_instances = {
      dv-ncr-db-1-a = merge(local.database_ec2_default, {
        cloudwatch_metric_alarms = merge(
          local.database_cloudwatch_metric_alarms.standard,
          local.database_cloudwatch_metric_alarms.db_connected,
          local.database_cloudwatch_metric_alarms.db_backup,
        )
        config = merge(local.database_ec2_default.config, {
          instance_profile_policies = concat(local.database_ec2_default.config.instance_profile_policies, [
            "Ec2T1DatabasePolicy",
          ])
        })
        tags = merge(local.database_ec2_default.tags, {
          description                          = "T1 NCR DATABASE"
          nomis-combined-reporting-environment = "t1"
          oracle-sids                          = "T1BIPSYS T1BIPAUD"
          instance-scheduling                  = "skip-scheduling"
        })
      })
      dv-ncr-web-admin-a = merge(local.tomcat_admin_ec2_default, {
        cloudwatch_metric_alarms = local.tomcat_admin_cloudwatch_metric_alarms
        config = merge(local.tomcat_admin_ec2_default.config, {
          instance_profile_policies = concat(local.tomcat_admin_ec2_default.config.instance_profile_policies, [
            "Ec2T1ReportingPolicy",
          ])
        })
        tags = merge(local.tomcat_admin_ec2_default.tags, {
          description                          = "For testing SAP BI Platform tomcat admin installation and configurations"
          nomis-combined-reporting-environment = "t1"
        })
      })
      dv-ncr-cms-a = merge(local.bip_cms_ec2_default, {
        cloudwatch_metric_alarms = local.bip_cms_cloudwatch_metric_alarms
        config = merge(local.bip_cms_ec2_default.config, {
          instance_profile_policies = concat(local.bip_cms_ec2_default.config.instance_profile_policies, [
            "Ec2T1ReportingPolicy",
          ])
        })
        tags = merge(local.bip_cms_ec2_default.tags, {
          description                          = "For testing SAP BI Platform CMS installation and configurations"
          nomis-combined-reporting-environment = "t1"
          node                                 = "1"
        })
      })
    }
    baseline_route53_zones = {
      "development.reporting.nomis.service.justice.gov.uk" = {
      }
    }
  }
}
