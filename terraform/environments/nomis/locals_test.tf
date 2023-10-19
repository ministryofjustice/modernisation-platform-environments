# nomis-test environment settings
locals {

  # baseline config
  test_config = {

    cloudwatch_metric_alarms_dbnames = [
      "T1CNOM",
      "T1NDH",
      "T1MIS",
      "T1CNMAUD",
      "T2CNOM",
      "T2NDH",
      "T3CNOM"
    ]

    cloudwatch_metric_alarms_dbnames_misload = [
      "T1MIS"
    ]

    baseline_s3_buckets = {
      nomis-db-backup-bucket = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        iam_policies   = module.baseline_presets.s3_iam_policies
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.DevTestEnvironmentsReadOnlyAccessBucketPolicy,
        ]
      }

      # use this bucket for storing artefacts for use across all accounts
      ec2-image-builder-nomis = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
          module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy,
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
      }
    }

    baseline_acm_certificates = {
      nomis_wildcard_cert = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.${module.environment.domains.public.application_environment}",
          "*.${local.environment}.nomis.service.justice.gov.uk",
          "*.${local.environment}.nomis.az.justice.gov.uk",
          "*.hmpp-azdt.justice.gov.uk",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "wildcard cert for nomis ${local.environment} domains"
        }
      }
    }

    baseline_iam_policies = {
      Ec2T1DatabasePolicy = {
        description = "Permissions required for T1 Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "ssm:GetParameter",
              "ssm:PutParameter",
            ]
            resources = [
              "arn:aws:ssm:*:*:parameter/azure/*",
              "arn:aws:ssm:*:*:parameter/oracle/database/*T1/*",
              "arn:aws:ssm:*:*:parameter/oracle/database/T1*/*",
            ]
          }
        ]
      }
      Ec2T2DatabasePolicy = {
        description = "Permissions required for T2 Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "ssm:GetParameter",
              "ssm:PutParameter",
            ]
            resources = [
              "arn:aws:ssm:*:*:parameter/azure/*",
              "arn:aws:ssm:*:*:parameter/oracle/database/*T2/*",
              "arn:aws:ssm:*:*:parameter/oracle/database/T2*/*",
            ]
          }
        ]
      }
      Ec2T3DatabasePolicy = {
        description = "Permissions required for T3 Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "ssm:GetParameter",
              "ssm:PutParameter",
            ]
            resources = [
              "arn:aws:ssm:*:*:parameter/azure/*",
              "arn:aws:ssm:*:*:parameter/oracle/database/*T3/*",
              "arn:aws:ssm:*:*:parameter/oracle/database/T3*/*",
            ]
          }
        ]
      }
      Ec2T1WeblogicPolicy = {
        description = "Permissions required for T1 Weblogic EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "ssm:GetParameter",
              "ssm:PutParameter",
            ]
            resources = [
              "arn:aws:ssm:*:*:parameter/oracle/weblogic/t1/*",
              "arn:aws:ssm:*:*:parameter/oracle/database/*T1/weblogic-passwords",
              "arn:aws:ssm:*:*:parameter/oracle/database/T1*/weblogic-passwords",
            ]
          }
        ]
      }
      Ec2T2WeblogicPolicy = {
        description = "Permissions required for T2 Weblogic EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "ssm:GetParameter",
              "ssm:PutParameter",
            ]
            resources = [
              "arn:aws:ssm:*:*:parameter/oracle/weblogic/t2/*",
              "arn:aws:ssm:*:*:parameter/oracle/database/*T2/weblogic-passwords",
              "arn:aws:ssm:*:*:parameter/oracle/database/T2*/weblogic-passwords",
            ]
          }
        ]
      }
      Ec2T3WeblogicPolicy = {
        description = "Permissions required for T3 Weblogic EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "ssm:GetParameter",
              "ssm:PutParameter",
            ]
            resources = [
              "arn:aws:ssm:*:*:parameter/oracle/weblogic/t3/*",
              "arn:aws:ssm:*:*:parameter/oracle/database/*T3/weblogic-passwords",
              "arn:aws:ssm:*:*:parameter/oracle/database/T3*/weblogic-passwords",
            ]
          }
        ]
      }
    }

    baseline_ssm_parameters = {
      "/oracle/weblogic/t1"       = local.weblogic_ssm_parameters
      "/oracle/weblogic/t2"       = local.weblogic_ssm_parameters
      "/oracle/weblogic/t3"       = local.weblogic_ssm_parameters
      "/oracle/database/T1CNOM"   = local.database_nomis_ssm_parameters
      "/oracle/database/T1NDH"    = local.database_ssm_parameters
      "/oracle/database/T1TRDAT"  = local.database_ssm_parameters
      "/oracle/database/T1CNMAUD" = local.database_ssm_parameters
      "/oracle/database/T1MIS"    = local.database_mis_ssm_parameters
      "/oracle/database/T1ORSYS"  = local.database_ssm_parameters
      "/oracle/database/T2CNOM"   = local.database_nomis_ssm_parameters
      "/oracle/database/T2NDH"    = local.database_ssm_parameters
      "/oracle/database/T2TRDAT"  = local.database_ssm_parameters
      "/oracle/database/T3CNOM"   = local.database_nomis_ssm_parameters
    }

    baseline_ec2_autoscaling_groups = {

      # NOT-ACTIVE (blue deployment)
      t1-nomis-web-a = merge(local.weblogic_ec2, {
        autoscaling_group = merge(local.weblogic_ec2.autoscaling_group, {
          desired_capacity = 0
        })
        cloudwatch_metric_alarms = local.weblogic_cloudwatch_metric_alarms
        config = merge(local.weblogic_ec2.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_*"
          instance_profile_policies = concat(local.weblogic_ec2.config.instance_profile_policies, [
            "Ec2T1WeblogicPolicy",
          ])
        })
        instance = merge(local.weblogic_ec2.instance, {
        })
        user_data_cloud_init = merge(local.weblogic_ec2.user_data_cloud_init, {
          args = merge(local.weblogic_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.weblogic_ec2.tags, {
          nomis-environment    = "t1"
          oracle-db-hostname-a = "t1nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t1nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T1CNOM"
          deployment           = "blue"
        })
      })

      # ACTIVE (green deployment)
      t1-nomis-web-b = merge(local.weblogic_ec2, {
        autoscaling_group = merge(local.weblogic_ec2.autoscaling_group, {
          desired_capacity = 1
        })
        # cloudwatch_metric_alarms = local.weblogic_cloudwatch_metric_alarms
        config = merge(local.weblogic_ec2.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
          instance_profile_policies = concat(local.weblogic_ec2.config.instance_profile_policies, [
            "Ec2T1WeblogicPolicy",
          ])
        })
        instance = merge(local.weblogic_ec2.instance, {
        })
        user_data_cloud_init = merge(local.weblogic_ec2.user_data_cloud_init, {
          args = merge(local.weblogic_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.weblogic_ec2.tags, {
          nomis-environment    = "t1"
          oracle-db-hostname-a = "t1nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t1nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T1CNOM"
          deployment           = "green"
        })
      })

      t1-nomis-xtag-a = merge(local.xtag_ec2, {
        autoscaling_group = merge(local.xtag_ec2.autoscaling_group, {
          desired_capacity = 0
        })
        # cloudwatch_metric_alarms = local.xtag_cloudwatch_metric_alarms
        config = merge(local.xtag_ec2.config, {
          ami_name = "nomis_rhel_7_9_weblogic_xtag_10_3_release_*"
          instance_profile_policies = concat(local.xtag_ec2.config.instance_profile_policies, [
            "Ec2T1WeblogicPolicy",
          ])
        })
        user_data_cloud_init = merge(local.xtag_ec2.user_data_cloud_init, {
          args = merge(local.xtag_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.xtag_ec2.tags, {
          nomis-environment    = "t1"
          oracle-db-hostname-a = "t1nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t1nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T1CNOM"
          ndh-ems-hostname     = "t1pml0005"
        })
      })
      t1-nomis-xtag-b = merge(local.xtag_ec2, {
        autoscaling_group = merge(local.xtag_ec2.autoscaling_group, {
          desired_capacity = 1
        })
        cloudwatch_metric_alarms = local.xtag_cloudwatch_metric_alarms
        config = merge(local.xtag_ec2.config, {
          ami_name = "nomis_rhel_7_9_weblogic_xtag_10_3_release_2023-07-19T09-01-29.168Z"
          instance_profile_policies = concat(local.xtag_ec2.config.instance_profile_policies, [
            "Ec2T1WeblogicPolicy",
          ])
        })
        user_data_cloud_init = merge(local.xtag_ec2.user_data_cloud_init, {
          args = merge(local.xtag_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.xtag_ec2.tags, {
          nomis-environment    = "t1"
          oracle-db-hostname-a = "t1nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t1nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T1CNOM"
          ndh-ems-hostname     = "t1pml0005"
        })
      })

      # NOT-ACTIVE (blue deployment)
      t2-nomis-web-a = merge(local.weblogic_ec2, {
        autoscaling_group = merge(local.weblogic_ec2.autoscaling_group, {
          desired_capacity = 0
        })
        cloudwatch_metric_alarms = local.weblogic_cloudwatch_metric_alarms
        config = merge(local.weblogic_ec2.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_*"
          instance_profile_policies = concat(local.weblogic_ec2.config.instance_profile_policies, [
            "Ec2T2WeblogicPolicy",
          ])
        })
        instance = merge(local.weblogic_ec2.instance, {
        })
        user_data_cloud_init = merge(local.weblogic_ec2.user_data_cloud_init, {
          args = merge(local.weblogic_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.weblogic_ec2.tags, {
          nomis-environment    = "t2"
          oracle-db-hostname-a = "t2nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t2nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T2CNOM"
          deployment           = "blue"
        })
      })

      # ACTIVE (green deployment)
      t2-nomis-web-b = merge(local.weblogic_ec2, {
        autoscaling_group = merge(local.weblogic_ec2.autoscaling_group, {
          desired_capacity = 1
        })
        # cloudwatch_metric_alarms = local.weblogic_cloudwatch_metric_alarms
        config = merge(local.weblogic_ec2.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
          instance_profile_policies = concat(local.weblogic_ec2.config.instance_profile_policies, [
            "Ec2T2WeblogicPolicy",
          ])
        })
        instance = merge(local.weblogic_ec2.instance, {
        })
        user_data_cloud_init = merge(local.weblogic_ec2.user_data_cloud_init, {
          args = merge(local.weblogic_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.weblogic_ec2.tags, {
          nomis-environment    = "t2"
          oracle-db-hostname-a = "t2nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t2nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T2CNOM"
          deployment           = "green"
        })
      })

      t2-nomis-xtag-a = merge(local.xtag_ec2, {
        autoscaling_group = merge(local.xtag_ec2.autoscaling_group, {
          desired_capacity = 0
        })
        # cloudwatch_metric_alarms = local.xtag_cloudwatch_metric_alarms
        config = merge(local.xtag_ec2.config, {
          ami_name = "nomis_rhel_7_9_weblogic_xtag_10_3_release_*"
          instance_profile_policies = concat(local.xtag_ec2.config.instance_profile_policies, [
            "Ec2T2WeblogicPolicy",
          ])
        })
        user_data_cloud_init = merge(local.xtag_ec2.user_data_cloud_init, {
          args = merge(local.xtag_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.xtag_ec2.tags, {
          nomis-environment    = "t2"
          oracle-db-hostname-a = "t2nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t2nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T2CNOM"
          ndh-ems-hostname     = "t2pml0008"
        })
      })
      t2-nomis-xtag-b = merge(local.xtag_ec2, {
        autoscaling_group = merge(local.xtag_ec2.autoscaling_group, {
          desired_capacity = 1
        })
        cloudwatch_metric_alarms = local.xtag_cloudwatch_metric_alarms
        config = merge(local.xtag_ec2.config, {
          ami_name = "nomis_rhel_7_9_weblogic_xtag_10_3_release_2023-07-19T09-01-29.168Z"
          instance_profile_policies = concat(local.xtag_ec2.config.instance_profile_policies, [
            "Ec2T2WeblogicPolicy",
          ])
        })
        user_data_cloud_init = merge(local.xtag_ec2.user_data_cloud_init, {
          args = merge(local.xtag_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.xtag_ec2.tags, {
          nomis-environment    = "t2"
          oracle-db-hostname-a = "t2nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t2nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T2CNOM"
          ndh-ems-hostname     = "t2pml0008"
        })
      })

      # NOT-ACTIVE (blue deployment)
      t3-nomis-web-a = merge(local.weblogic_ec2, {
        autoscaling_group = merge(local.weblogic_ec2.autoscaling_group, {
          desired_capacity = 0
        })
        cloudwatch_metric_alarms = local.weblogic_cloudwatch_metric_alarms
        config = merge(local.weblogic_ec2.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_*"
          instance_profile_policies = concat(local.weblogic_ec2.config.instance_profile_policies, [
            "Ec2T3WeblogicPolicy",
          ])
        })
        instance = merge(local.weblogic_ec2.instance, {
          # instance_type = "t2.xlarge"
        })
        user_data_cloud_init = merge(local.weblogic_ec2.user_data_cloud_init, {
          args = merge(local.weblogic_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.weblogic_ec2.tags, {
          nomis-environment    = "t3"
          oracle-db-hostname-a = "t3nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t3nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T3CNOM"
          deployment           = "blue"
        })
      })

      # ACTIVE (green deployment)
      t3-nomis-web-b = merge(local.weblogic_ec2, {
        autoscaling_group = merge(local.weblogic_ec2.autoscaling_group, {
          desired_capacity = 1
        })
        # cloudwatch_metric_alarms = local.weblogic_cloudwatch_metric_alarms
        config = merge(local.weblogic_ec2.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
          instance_profile_policies = concat(local.weblogic_ec2.config.instance_profile_policies, [
            "Ec2T3WeblogicPolicy",
          ])
        })
        instance = merge(local.weblogic_ec2.instance, {
          instance_type = "t2.xlarge"
        })
        user_data_cloud_init = merge(local.weblogic_ec2.user_data_cloud_init, {
          args = merge(local.weblogic_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.weblogic_ec2.tags, {
          nomis-environment    = "t3"
          oracle-db-hostname-a = "t3nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t3nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T3CNOM"
          deployment           = "green"
        })
      })

      test-jumpserver-a = merge(local.jumpserver_ec2, {
        config = merge(local.jumpserver_ec2.config, {
          user_data_raw = base64encode(templatefile("./templates/jumpserver-user-data.yaml.tftpl", {
            ie_compatibility_mode_site_list = join(",", [
              "t1-nomis-web-a.test.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
              "t1-nomis-web-b.test.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
              "t1-cn.hmpp-azdt.justice.gov.uk:7777/forms/frmservlet?config=tag",
              "t1-cn.hmpp-azdt.justice.gov.uk/forms/frmservlet?config=tag",
              "c-t1.test.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
              "t2-nomis-web-a.test.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
              "t2-nomis-web-b.test.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
              "t2-cn.hmpp-azdt.justice.gov.uk/forms/frmservlet?config=tag",
              "c-t2.test.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
              "t3-nomis-web-a.test.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
              "t3-nomis-web-b.test.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
              "t3-cn.hmpp-azdt.justice.gov.uk/forms/frmservlet?config=tag",
              "t3-cn-ha.hmpp-azdt.justice.gov.uk/forms/frmservlet?config=tag",
              "c-t3.test.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
            ])
            ie_trusted_domains = join(",", [
              "*.nomis.hmpps-test.modernisation-platform.justice.gov.uk",
              "*.nomis.service.justice.gov.uk",
              "*.hmpp-azdt.justice.gov.uk",
            ])
            desktop_shortcuts = join(",", [
              "T1 NOMIS|https://c-t1.test.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
              "T2 NOMIS|https://c-t2.test.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
              "T3 NOMIS|https://c-t3.test.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
            ])
          }))
        })
      })
    }

    baseline_ec2_instances = {
      t1-nomis-db-1-a = merge(local.database_ec2, {
        cloudwatch_metric_alarms = local.database_ec2_cloudwatch_metric_alarms
        config = merge(local.database_ec2.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-06-23T16-28-48.100Z"
          availability_zone = "${local.region}a"
          instance_profile_policies = concat(local.database_ec2.config.instance_profile_policies, [
            "Ec2T1DatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.database_ec2.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 100 }
        })
        ebs_volume_config = merge(local.database_ec2.ebs_volume_config, {
          data  = { total_size = 500 }
          flash = { total_size = 50 }
        })
        tags = merge(local.database_ec2.tags, {
          nomis-environment   = "t1"
          description         = "T1 NOMIS database"
          oracle-sids         = "T1CNOM T1NDH T1TRDAT T1ORSYS"
          instance-scheduling = "skip-scheduling"
        })
      })

      t1-nomis-db-2-a = merge(local.database_ec2, {
        cloudwatch_metric_alarms = local.database_ec2_cloudwatch_metric_alarms
        config = merge(local.database_ec2.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-06-23T16-28-48.100Z"
          availability_zone = "${local.region}a"
          instance_profile_policies = concat(local.database_ec2.config.instance_profile_policies, [
            "Ec2T1DatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.database_ec2.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 100 }
        })
        ebs_volume_config = merge(local.database_ec2.ebs_volume_config, {
          data  = { total_size = 500 }
          flash = { total_size = 50 }
        })
        tags = merge(local.database_ec2.tags, {
          nomis-environment   = "t1"
          description         = "T1 NOMIS Audit and MIS database"
          oracle-sids         = "T1MIS T1CNMAUD"
          instance-scheduling = "skip-scheduling"
          misload-dbname      = "T1MIS"
        })
      })

      t2-nomis-db-1-a = merge(local.database_ec2, {
        cloudwatch_metric_alarms = local.database_ec2_cloudwatch_metric_alarms
        config = merge(local.database_ec2.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-06-23T16-28-48.100Z"
          availability_zone = "${local.region}a"
          instance_profile_policies = concat(local.database_ec2.config.instance_profile_policies, [
            "Ec2T2DatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.database_ec2.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 100 }
        })
        ebs_volume_config = merge(local.database_ec2.ebs_volume_config, {
          data  = { total_size = 500 }
          flash = { total_size = 50 }
        })
        tags = merge(local.database_ec2.tags, {
          nomis-environment   = "t2"
          description         = "T2 NOMIS database"
          oracle-sids         = "T2CNOM T2NDH T2TRDAT"
          instance-scheduling = "skip-scheduling"
        })
      })

      t3-nomis-db-1 = merge(local.database_ec2, {
        cloudwatch_metric_alarms = local.database_ec2_cloudwatch_metric_alarms
        config = merge(local.database_ec2.config, {
          availability_zone = "${local.region}a"
          instance_profile_policies = concat(local.database_ec2.config.instance_profile_policies, [
            "Ec2T3DatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.database_ec2.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 500 }
        })
        ebs_volume_config = merge(local.database_ec2.ebs_volume_config, {
          data  = { total_size = 2000 }
          flash = { total_size = 500 }
        })
        tags = merge(local.database_ec2.tags, {
          nomis-environment   = "t3"
          description         = "T3 NOMIS database to replace Azure T3PDL0070"
          oracle-sids         = "T3CNOM"
          instance-scheduling = "skip-scheduling"
        })
      })

    }

    baseline_lbs = {
      # AWS doesn't let us call it internal
      private = {
        internal_lb              = true
        enable_delete_protection = false
        force_destroy_bucket     = true
        idle_timeout             = 3600
        public_subnets           = module.environment.subnets["private"].ids
        security_groups          = ["private-lb"]

        listeners = {
          http = local.weblogic_lb_listeners.http

          http7777 = merge(local.weblogic_lb_listeners.http7777, {
            rules = {
              # T1 users in Azure accessed server directly on http 7777
              # so support this in Mod Platform as well to minimise
              # disruption.  This isn't needed for other environments.
              t1-nomis-web-a = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-nomis-web-a.test.nomis.az.justice.gov.uk",
                      "t1-nomis-web-a.test.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t1-nomis-web-b = {
                priority = 400
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-nomis-web-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-nomis-web-b.test.nomis.az.justice.gov.uk",
                      "t1-nomis-web-b.test.nomis.service.justice.gov.uk",
                      "c-t1.test.nomis.az.justice.gov.uk",
                      "c-t1.test.nomis.service.justice.gov.uk",
                      "t1-cn.hmpp-azdt.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })

          https = merge(local.weblogic_lb_listeners.https, {
            alarm_target_group_names = [
              # "t1-nomis-web-a-http-7777",
              "t1-nomis-web-b-http-7777",
              # "t2-nomis-web-a-http-7777",
              "t2-nomis-web-b-http-7777",
              # "t3-nomis-web-a-http-7777",
              "t3-nomis-web-b-http-7777",
            ]
            rules = {
              t1-nomis-web-a-http-7777 = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-nomis-web-a.test.nomis.az.justice.gov.uk",
                      "t1-nomis-web-a.test.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t1-nomis-web-b-http-7777 = {
                priority = 450
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-nomis-web-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-nomis-web-b.test.nomis.az.justice.gov.uk",
                      "t1-nomis-web-b.test.nomis.service.justice.gov.uk",
                      "c-t1.test.nomis.az.justice.gov.uk",
                      "c-t1.test.nomis.service.justice.gov.uk",
                      "t1-cn.hmpp-azdt.justice.gov.uk",
                    ]
                  }
                }]
              }
              t2-nomis-web-a-http-7777 = {
                priority = 550
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t2-nomis-web-a.test.nomis.az.justice.gov.uk",
                      "t2-nomis-web-a.test.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t2-nomis-web-b-http-7777 = {
                priority = 600
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-nomis-web-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t2-nomis-web-b.test.nomis.az.justice.gov.uk",
                      "t2-nomis-web-b.test.nomis.service.justice.gov.uk",
                      "c-t2.test.nomis.az.justice.gov.uk",
                      "c-t2.test.nomis.service.justice.gov.uk",
                      "t2-cn.hmpp-azdt.justice.gov.uk",
                    ]
                  }
                }]
              }
              t3-nomis-web-a-http-7777 = {
                priority = 700
                actions = [{
                  type              = "forward"
                  target_group_name = "t3-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t3-nomis-web-a.test.nomis.az.justice.gov.uk",
                      "t3-nomis-web-a.test.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t3-nomis-web-b-http-7777 = {
                priority = 800
                actions = [{
                  type              = "forward"
                  target_group_name = "t3-nomis-web-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t3-nomis-web-b.test.nomis.az.justice.gov.uk",
                      "t3-nomis-web-b.test.nomis.service.justice.gov.uk",
                      "c-t3.test.nomis.az.justice.gov.uk",
                      "c-t3.test.nomis.service.justice.gov.uk",
                      "t3-cn.hmpp-azdt.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })
        }
      }
    }

    baseline_route53_zones = {
      "hmpps-test.modernisation-platform.service.justice.gov.uk" = {
        records = [
        ]
      }
      "test.nomis.az.justice.gov.uk" = {
        lb_alias_records = [
          # T1
          { name = "t1-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "t1-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-t1", type = "A", lbs_map_key = "private" },
          # T2
          { name = "t2-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "t2-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-t2", type = "A", lbs_map_key = "private" },
          # T3
          { name = "t3-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "t3-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-t3", type = "A", lbs_map_key = "private" },
        ]
      }
      "test.nomis.service.justice.gov.uk" = {
        records = [
          # T1 [1-a: T1CNOM, T1NDH, T1TRDAT, T1ORSYS] [2-a: T1MIS, T1CNMAUD]
          { name = "t1nomis", type = "CNAME", ttl = "300", records = ["t1nomis-a.test.nomis.service.justice.gov.uk"] },
          { name = "t1nomis-a", type = "CNAME", ttl = "300", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1nomis-b", type = "CNAME", ttl = "300", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1ndh", type = "CNAME", ttl = "300", records = ["t1ndh-a.test.nomis.service.justice.gov.uk"] },
          { name = "t1ndh-a", type = "CNAME", ttl = "300", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1ndh-b", type = "CNAME", ttl = "300", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1or", type = "CNAME", ttl = "300", records = ["t1or-a.test.nomis.service.justice.gov.uk"] },
          { name = "t1or-a", type = "CNAME", ttl = "300", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1or-b", type = "CNAME", ttl = "300", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1trdat", type = "CNAME", ttl = "300", records = ["t1trdat-a.test.nomis.service.justice.gov.uk"] },
          { name = "t1trdat-a", type = "CNAME", ttl = "300", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1trdat-b", type = "CNAME", ttl = "300", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1audit", type = "CNAME", ttl = "300", records = ["t1audit-a.test.nomis.service.justice.gov.uk"] },
          { name = "t1audit-a", type = "CNAME", ttl = "300", records = ["t1-nomis-db-2-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1audit-b", type = "CNAME", ttl = "300", records = ["t1-nomis-db-2-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1mis", type = "CNAME", ttl = "300", records = ["t1mis-a.test.nomis.service.justice.gov.uk"] },
          { name = "t1mis-a", type = "CNAME", ttl = "300", records = ["t1-nomis-db-2-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1mis-b", type = "CNAME", ttl = "300", records = ["t1-nomis-db-2-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          # T2 [1-a: T2CNOM, T2NDH, T2TRDAT]
          { name = "t2nomis", type = "CNAME", ttl = "300", records = ["t2nomis-a.test.nomis.service.justice.gov.uk"] },
          { name = "t2nomis-a", type = "CNAME", ttl = "300", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t2nomis-b", type = "CNAME", ttl = "300", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t2ndh", type = "CNAME", ttl = "300", records = ["t2ndh-a.test.nomis.service.justice.gov.uk"] },
          { name = "t2ndh-a", type = "CNAME", ttl = "300", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t2ndh-b", type = "CNAME", ttl = "300", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t2or", type = "CNAME", ttl = "300", records = ["t2or-a.test.nomis.service.justice.gov.uk"] },
          { name = "t2or-a", type = "CNAME", ttl = "300", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t2or-b", type = "CNAME", ttl = "300", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t2trdat", type = "CNAME", ttl = "300", records = ["t2trdat-a.test.nomis.service.justice.gov.uk"] },
          { name = "t2trdat-a", type = "CNAME", ttl = "300", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t2trdat-b", type = "CNAME", ttl = "300", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          # T3: [1-b: T3CNOM]
          { name = "t3nomis", type = "CNAME", ttl = "300", records = ["t3nomis-b.test.nomis.service.justice.gov.uk"] },
          { name = "t3nomis-a", type = "CNAME", ttl = "300", records = ["t3-nomis-db-1.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t3nomis-b", type = "CNAME", ttl = "300", records = ["t3-nomis-db-1.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
        ]
        lb_alias_records = [
          # T1
          { name = "t1-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "t1-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-t1", type = "A", lbs_map_key = "private" },
          # T2
          { name = "t2-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "t2-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-t2", type = "A", lbs_map_key = "private" },
          # T3
          { name = "t3-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "t3-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-t3", type = "A", lbs_map_key = "private" },
        ]
      }
    }
  }
}
