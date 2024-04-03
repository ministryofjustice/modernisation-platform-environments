locals {
  preproduction_config = {
    baseline_s3_buckets = {
      ncr-db-backup-bucket = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        iam_policies   = module.baseline_presets.s3_iam_policies
      }
    }
    baseline_acm_certificates = {
      nomis_combined_reporting_wildcard_cert = {
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.${module.environment.domains.public.application_environment}",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "Wildcard certificate for the ${local.environment} environment"
        }
      }
    }
    baseline_secretsmanager_secrets = {
      "/oracle/database/PREPRODBIPSYS" = local.database_secretsmanager_secrets
      "/oracle/database/PREPRODBIPAUD" = local.database_secretsmanager_secrets
    }

    baseline_iam_policies = {
      Ec2PREPRODDatabasePolicy = {
        description = "Permissions required for PREPROD Database EC2s"
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
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PREPROD/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PREPROD*/*",
            ]
          }
        ]
      }
      Ec2LSASTDatabasePolicy = {
        description = "Permissions required for LSAST Database EC2s"
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
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*LSAST/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/LSAST*/*",
            ]
          }
        ]
      }
      Ec2PREPRODReportingPolicy = {
        description = "Permissions required for PREPROD reporting EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/ec2/ncr-bip-cms/PREPROD/*",
              "arn:aws:secretsmanager:*:*:secret:/ec2/ncr-tomcat-admin/PREPROD/*",
            ]
          }
        ]
      }
      Ec2LSASTReportingPolicy = {
        description = "Permissions required for LSAST reporting EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/ec2/ncr-bip-cms/LSAST/*",
              "arn:aws:secretsmanager:*:*:secret:/ec2/ncr-tomcat-admin/LSAST/*",
            ]
          }
        ]
      }
    }
    baseline_ec2_instances = {

      ### PREPROD

      # preprod-ncr-cms-1 = merge(local.bip_cms_ec2_default, {
      #   cloudwatch_metric_alarms = local.bip_cms_cloudwatch_metric_alarms
      #   config = merge(local.bip_cms_ec2_default.config, {
      #     instance_profile_policies = concat(local.bip_cms_ec2_default.config.instance_profile_policies, [
      #       "Ec2PREPRODReportingPolicy",
      #     ])
      #   })
      #   instance = merge(local.bip_cms_ec2_default.instance, {
      #     instance_type = "c5.4xlarge",
      #   })
      #   tags = merge(local.bip_cms_ec2_default.tags, {
      #     description                          = "PreProd SAP BI Platform CMS installation and configurations"
      #     nomis-combined-reporting-environment = "preprod"
      #     node                                 = "1"
      #   })
      # })
      # preprod-ncr-cms-2 = merge(local.bip_cms_ec2_default, {
      #   cloudwatch_metric_alarms = local.bip_cms_cloudwatch_metric_alarms
      #   config = merge(local.bip_cms_ec2_default.config, {
      #     instance_profile_policies = concat(local.bip_cms_ec2_default.config.instance_profile_policies, [
      #       "Ec2PREPRODReportingPolicy",
      #     ])
      #   })
      #   instance = merge(local.bip_cms_ec2_default.instance, {
      #     instance_type = "c5.4xlarge",
      #   })
      #   tags = merge(local.bip_cms_ec2_default.tags, {
      #     description                          = "PreProd SAP BI Platform CMS installation and configurations"
      #     nomis-combined-reporting-environment = "preprod"
      #     node                                 = "2"
      #   })
      # })
      # preprod-ncr-processing-1 = merge(local.bip_cms_ec2_default, {
      #   cloudwatch_metric_alarms = local.bip_cms_cloudwatch_metric_alarms
      #   config = merge(local.bip_cms_ec2_default.config, {
      #     instance_profile_policies = concat(local.bip_cms_ec2_default.config.instance_profile_policies, [
      #       "Ec2PREPRODReportingPolicy",
      #     ])
      #   })
      #   instance = merge(local.bip_cms_ec2_default.instance, {
      #     instance_type = "c5.4xlarge",
      #   })
      #   tags = merge(local.bip_cms_ec2_default.tags, {
      #     description                          = "PreProd SAP BI Platform CMS installation and configurations"
      #     nomis-combined-reporting-environment = "preprod"
      #     node                                 = "3"
      #   })
      # })
      # preprod-ncr-web-admin = merge(local.tomcat_admin_ec2_default, {
      #   cloudwatch_metric_alarms = local.tomcat_admin_cloudwatch_metric_alarms
      #   config = merge(local.tomcat_admin_ec2_default.config, {
      #     instance_profile_policies = concat(local.tomcat_admin_ec2_default.config.instance_profile_policies, [
      #       "Ec2PREPRODReportingPolicy",
      #     ])
      #   })
      #   instance = merge(local.bip_cms_ec2_default.instance, {
      #     instance_type = "r7i.large",
      #   })
      #   tags = merge(local.tomcat_admin_ec2_default.tags, {
      #     description                          = "PreProd SAP BI Platform tomcat admin installation and configurations"
      #     nomis-combined-reporting-environment = "preprod"
      #   })
      # })
      # preprod-ncr-web-1 = merge(local.tomcat_admin_ec2_default, {
      #   cloudwatch_metric_alarms = local.tomcat_admin_cloudwatch_metric_alarms
      #   config = merge(local.tomcat_admin_ec2_default.config, {
      #     instance_profile_policies = concat(local.tomcat_admin_ec2_default.config.instance_profile_policies, [
      #       "Ec2PREPRODReportingPolicy",
      #     ])
      #   })
      #   instance = merge(local.bip_cms_ec2_default.instance, {
      #     instance_type = "r7i.large",
      #   })
      #   tags = merge(local.tomcat_admin_ec2_default.tags, {
      #     description                          = "PreProd SAP BI Platform tomcat installation and configurations"
      #     nomis-combined-reporting-environment = "preprod"
      #   })
      # })
      # preprod-ncr-web-2 = merge(local.tomcat_admin_ec2_default, {
      #   cloudwatch_metric_alarms = local.tomcat_admin_cloudwatch_metric_alarms
      #   config = merge(local.tomcat_admin_ec2_default.config, {
      #     instance_profile_policies = concat(local.tomcat_admin_ec2_default.config.instance_profile_policies, [
      #       "Ec2PREPRODReportingPolicy",
      #     ])
      #   })
      #   instance = merge(local.bip_cms_ec2_default.instance, {
      #     instance_type = "r7i.xlarge",
      #   })
      #   tags = merge(local.tomcat_admin_ec2_default.tags, {
      #     description                          = "PreProd SAP BI Platform tomcat installation and configurations"
      #     nomis-combined-reporting-environment = "preprod"
      #   })
      # })
      preprod-ncr-db-1-a = merge(local.database_ec2_default, {
        cloudwatch_metric_alarms = merge(
          local.database_cloudwatch_metric_alarms.standard,
          local.database_cloudwatch_metric_alarms.db_connected,
          local.database_cloudwatch_metric_alarms.db_backup,
        )
        config = merge(local.database_ec2_default.config, {
          instance_profile_policies = concat(local.database_ec2_default.config.instance_profile_policies, [
            "Ec2PREPRODDatabasePolicy",
          ])
        })
        tags = merge(local.database_ec2_default.tags, {
          description                          = "PREPROD NCR DATABASE"
          nomis-combined-reporting-environment = "preprod"
          oracle-sids                          = "PREPRODBIPSYS PREPRODBIPAUD"
          instance-scheduling                  = "skip-scheduling"
        })
      })

      ### LSAST

      # lsast-ncr-cms-1 = merge(local.bip_cms_ec2_default, {
      #   cloudwatch_metric_alarms = local.bip_cms_cloudwatch_metric_alarms
      #   config = merge(local.bip_cms_ec2_default.config, {
      #     instance_profile_policies = concat(local.bip_cms_ec2_default.config.instance_profile_policies, [
      #       "Ec2LSASTReportingPolicy",
      #     ])
      #   })
      #   instance = merge(local.bip_cms_ec2_default.instance, {
      #     instance_type = "c5.4xlarge",
      #   })
      #   tags = merge(local.bip_cms_ec2_default.tags, {
      #     description                          = "LSAST SAP BI Platform CMS installation and configurations"
      #     nomis-combined-reporting-environment = "lsast"
      #     node                                 = "1"
      #   })
      # })

      # lsast-ncr-web-1 = merge(local.tomcat_admin_ec2_default, {
      #   cloudwatch_metric_alarms = local.tomcat_admin_cloudwatch_metric_alarms
      #   config = merge(local.tomcat_admin_ec2_default.config, {
      #     instance_profile_policies = concat(local.tomcat_admin_ec2_default.config.instance_profile_policies, [
      #       "Ec2LSASTReportingPolicy",
      #     ])
      #   })
      #   instance = merge(local.bip_cms_ec2_default.instance, {
      #     instance_type = "r7i.xlarge",
      #   })
      #   tags = merge(local.tomcat_admin_ec2_default.tags, {
      #     description                          = "LSAST SAP BI Platform tomcat installation and configurations"
      #     nomis-combined-reporting-environment = "lsast"
      #   })
      # })

      # lsast-ncr-db-1-a = merge(local.database_ec2_default, {
      #   cloudwatch_metric_alarms = merge(
      #     local.database_cloudwatch_metric_alarms.standard,
      #     local.database_cloudwatch_metric_alarms.db_connected,
      #     local.database_cloudwatch_metric_alarms.db_backup,
      #   )
      #   config = merge(local.database_ec2_default.config, {
      #     instance_profile_policies = concat(local.database_ec2_default.config.instance_profile_policies, [
      #       "Ec2LSASTDatabasePolicy",
      #     ])
      #   })
      #   tags = merge(local.database_ec2_default.tags, {
      #     description                          = "LSAST NCR DATABASE"
      #     nomis-combined-reporting-environment = "lsast"
      #     oracle-sids                          = "LSASTBIPSYS LSASTBIPAUD"
      #     instance-scheduling                  = "skip-scheduling"
      #   })
      # })

    }
    baseline_route53_zones = {
      "preproduction.reporting.nomis.service.justice.gov.uk" = {
        records = [
          { name = "preprod-ncr", type = "CNAME", ttl = "300", records = ["t1ncr-a.preproduction.reporting.nomis.service.justice.gov.uk"] },
          { name = "preprod-ncr-a", type = "CNAME", ttl = "300", records = ["t1-ncr-db-1-a.nomis-combined-reporting.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "preprod-ncr-b", type = "CNAME", ttl = "300", records = ["t1-ncr-db-1-b.nomis-combined-reporting.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
        ]
      }
    }
  }
}
