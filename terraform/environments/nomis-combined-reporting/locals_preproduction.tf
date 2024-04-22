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
      "/oracle/database/PPBIPSYS" = local.database_secretsmanager_secrets
      "/oracle/database/PPBIPAUD" = local.database_secretsmanager_secrets
    }

    baseline_iam_policies = {
      Ec2PPDatabasePolicy = {
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
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PP/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PP*/*",
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
      Ec2PPReportingPolicy = {
        description = "Permissions required for PP reporting EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/ec2/ncr-bip-cms/PP/*",
              "arn:aws:secretsmanager:*:*:secret:/ec2/ncr-tomcat-admin/PP/*",
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

      pp-ncr-cms-1 = merge(local.bip_cms_ec2_default, {
        cloudwatch_metric_alarms = local.bip_cms_cloudwatch_metric_alarms
        config = merge(local.bip_cms_ec2_default.config, {
          instance_profile_policies = concat(local.bip_ec2_default.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.bip_cms_ec2_default.instance, {
          instance_type = "c5.4xlarge",
        })
        tags = merge(local.bip_cms_ec2_default.tags, {
          description                          = "PreProd SAP BI Platform CMS installation and configurations"
          nomis-combined-reporting-environment = "preprod"
          node                                 = "1"
        })
      })
      pp-ncr-cms-2 = merge(local.bip_cms_ec2_default, {
        cloudwatch_metric_alarms = local.bip_cms_cloudwatch_metric_alarms
        config = merge(local.bip_cms_ec2_default.config, {
          instance_profile_policies = concat(local.bip_ec2_default.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.bip_cms_ec2_default.instance, {
          instance_type = "c5.4xlarge",
        })
        tags = merge(local.bip_cms_ec2_default.tags, {
          description                          = "PreProd SAP BI Platform CMS installation and configurations"
          nomis-combined-reporting-environment = "preprod"
          node                                 = "2"
        })
      })
      pp-ncr-processing-1 = merge(local.bip_cms_ec2_default, {
        cloudwatch_metric_alarms = local.bip_cms_cloudwatch_metric_alarms
        config = merge(local.bip_cms_ec2_default.config, {
          instance_profile_policies = concat(local.bip_ec2_default.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.bip_cms_ec2_default.instance, {
          instance_type = "c5.4xlarge",
        })
        tags = merge(local.bip_cms_ec2_default.tags, {
          description                          = "PreProd SAP BI Platform installation and configurations"
          nomis-combined-reporting-environment = "preprod"
          node                                 = "3"
        })
      })
      pp-ncr-web-admin = merge(local.web_ec2_default, {
        cloudwatch_metric_alarms = local.web_cloudwatch_metric_alarms
        config = merge(local.web_ec2_default.config, {
          instance_profile_policies = concat(local.web_ec2_default.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.bip_cms_ec2_default.instance, {
          instance_type = "r7i.large",
        })
        tags = merge(local.web_ec2_default.tags, {
          description                          = "PreProd SAP BI Platform tomcat admin installation and configurations"
          nomis-combined-reporting-environment = "preprod"
        })
      })
      pp-ncr-web-1 = merge(local.web_ec2_default, {
        cloudwatch_metric_alarms = local.web_cloudwatch_metric_alarms
        config = merge(local.web_ec2_default.config, {
          instance_profile_policies = concat(local.web_ec2_default.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.bip_cms_ec2_default.instance, {
          instance_type = "r7i.large",
        })
        tags = merge(local.web_ec2_default.tags, {
          description                          = "PreProd SAP BI Platform tomcat installation and configurations"
          nomis-combined-reporting-environment = "preprod"
        })
      })
      pp-ncr-web-2 = merge(local.web_ec2_default, {
        cloudwatch_metric_alarms = local.web_cloudwatch_metric_alarms
        config = merge(local.web_ec2_default.config, {
          instance_profile_policies = concat(local.web_ec2_default.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.bip_cms_ec2_default.instance, {
          instance_type = "r7i.xlarge",
        })
        tags = merge(local.web_ec2_default.tags, {
          description                          = "PreProd SAP BI Platform tomcat installation and configurations"
          nomis-combined-reporting-environment = "preprod"
        })
      })
      pp-ncr-etl-1-a = merge(local.etl_ec2_default, {
        cloudwatch_metric_alarms = local.etl_cloudwatch_metric_alarms
        config = merge(local.etl_ec2_default.config, {
          instance_profile_policies = concat(local.etl_ec2_default.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        tags = merge(local.etl_ec2_default.tags, {
          description                          = "PreProd SAP BI Platform ETL installation and configurations"
          nomis-combined-reporting-environment = "preprod"
          instance-scheduling                  = "skip-scheduling"
        })
      })
      pp-ncr-db-1-a = merge(local.database_ec2_default, {
        cloudwatch_metric_alarms = merge(
          local.database_cloudwatch_metric_alarms.standard,
          local.database_cloudwatch_metric_alarms.db_connected,
          local.database_cloudwatch_metric_alarms.db_backup,
        )
        config = merge(local.database_ec2_default.config, {
          instance_profile_policies = concat(local.database_ec2_default.config.instance_profile_policies, [
            "Ec2PPDatabasePolicy",
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
          description                          = "PREPROD NCR DATABASE"
          nomis-combined-reporting-environment = "pp"
          oracle-sids                          = "PPBIPSYS PPBIPAUD"
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

      # lsast-ncr-web-1 = merge(local.web_ec2_default, {
      #   cloudwatch_metric_alarms = local.web_cloudwatch_metric_alarms
      #   config = merge(local.web_ec2_default.config, {
      #     instance_profile_policies = concat(local.web_ec2_default.config.instance_profile_policies, [
      #       "Ec2LSASTReportingPolicy",
      #     ])
      #   })
      #   instance = merge(local.bip_cms_ec2_default.instance, {
      #     instance_type = "r7i.xlarge",
      #   })
      #   tags = merge(local.web_ec2_default.tags, {
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
          { name = "db", type = "CNAME", ttl = "3600", records = ["pp-ncr-db-1-a.nomis-combined-reporting.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] }
        ]
      }
    }
  }
}
