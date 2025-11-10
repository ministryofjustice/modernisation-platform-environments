locals {

  baseline_presets_test = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "oasys-national-reporting-test"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_test = {

    acm_certificates = {
      oasys_national_reporting_wildcard_cert = {
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "modernisation-platform.service.justice.gov.uk"
        external_validation_records_created = true
        subject_alternate_names = [
          "*.oasys-national-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk",
          "test.reporting.oasys.service.justice.gov.uk",
          "*.test.reporting.oasys.service.justice.gov.uk",
        ] # NOTE: there is no azure cert equivalent for T2
        tags = {
          description = "Wildcard certificate for the test environment"
        }
      }
    }

    efs = {
      t2-onr-sap-share = {
        access_points = {
          root = {
            posix_user = {
              gid = 1201 # binstall
              uid = 1201 # bobj
            }
            root_directory = {
              path = "/"
              creation_info = {
                owner_gid   = 1201 # binstall
                owner_uid   = 1201 # bobj
                permissions = "0777"
              }
            }
          }
        }
        file_system = {
          availability_zone_name = "eu-west-2a"
          lifecycle_policy = {
            transition_to_ia = "AFTER_30_DAYS"
          }
        }
        mount_targets = [{
          subnet_name        = "private"
          availability_zones = ["eu-west-2a"]
          security_groups    = ["efs"]
        }]
        tags = {
          backup      = "false"
          backup-plan = "daily-and-weekly"
        }
      }
    }

    ec2_instances = {

      t2-onr-bods-1 = merge(local.ec2_instances.bods, {
        config = merge(local.ec2_instances.bods.config, {
          ami_name          = "hmpps_windows_server_2019_release_2024-12-02T00-00-37.662Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bods.config.instance_profile_policies, [
            "Ec2T2BodsPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bods.instance, {
          instance_type = "m4.xlarge"
          tags = merge(local.ec2_instances.bods.instance.tags, {
            patch-manager = "weds1500"
          })
        })
        cloudwatch_metric_alarms = merge(
          module.baseline_presets.cloudwatch_metric_alarms.ec2,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows,
          local.cloudwatch_metric_alarms.windows,
          local.cloudwatch_metric_alarms.bods_primary,
        )
        tags = merge(local.ec2_instances.bods.tags, {
          oasys-national-reporting-environment = "t2"
          domain-name                          = "azure.noms.root"
        })
      })

      t2-onr-bods-2 = merge(local.ec2_instances.bods, {
        config = merge(local.ec2_instances.bods.config, {
          ami_name          = "hmpps_windows_server_2019_release_2024-12-02T00-00-37.662Z"
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.bods.config.instance_profile_policies, [
            "Ec2T2BodsPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bods.instance, {
          instance_type = "m4.xlarge"
          tags = merge(local.ec2_instances.bods.instance.tags, {
            patch-manager = "thurs1500"
          })
        })
        cloudwatch_metric_alarms = merge(
          module.baseline_presets.cloudwatch_metric_alarms.ec2,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows,
          local.cloudwatch_metric_alarms.windows,
          local.cloudwatch_metric_alarms.bods_secondary,
        )
        tags = merge(local.ec2_instances.bods.tags, {
          oasys-national-reporting-environment = "t2"
          domain-name                          = "azure.noms.root"
        })
      })

      t2-onr-cms-1 = merge(local.ec2_instances.bip_cms, {
        config = merge(local.ec2_instances.bip_cms.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_cms.config.instance_profile_policies, [
            "Ec2T2ReportingPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip_cms.instance, {
          instance_type = "m6i.xlarge"
        })
        user_data_cloud_init = merge(local.ec2_instances.bip_cms.user_data_cloud_init, {
          args = merge(local.ec2_instances.bip_cms.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.bip_cms.tags, {
          instance-scheduling                  = "skip-scheduling"
          oasys-national-reporting-environment = "t2"
        })
      })

      t2-onr-web-1 = merge(local.ec2_instances.bip_web, {
        config = merge(local.ec2_instances.bip_web.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_web.config.instance_profile_policies, [
            "Ec2T2ReportingPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip_web.instance, {
          instance_type = "r6i.large"
        })
        user_data_cloud_init = merge(local.ec2_instances.bip_web.user_data_cloud_init, {
          args = merge(local.ec2_instances.bip_web.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.bip_web.tags, {
          instance-scheduling                  = "skip-scheduling"
          oasys-national-reporting-environment = "t2"
        })
      })
    }

    fsx_windows = {
      t2-bods-win-share = {
        aliases                         = ["t2-onr-fs.azure.noms.root"]
        automatic_backup_retention_days = 0
        deployment_type                 = "SINGLE_AZ_1"
        security_groups                 = ["bods"]
        skip_final_backup               = true
        storage_capacity                = 128
        throughput_capacity             = 8

        subnets = [
          {
            name               = "private"
            availability_zones = ["eu-west-2a"]
          }
        ]

        self_managed_active_directory = {
          dns_ips = flatten([
            module.ip_addresses.mp_ips.ad_fixngo_azure_domain_controllers,
          ])
          domain_name          = "azure.noms.root"
          username             = "svc_join_domain"
          password_secret_name = "/sap/bods/t2/passwords"
        }
        tags = {
          backup      = false
          backup-plan = "daily-and-weekly"
        }
      }
    }

    iam_policies = {
      Ec2T2BodsPolicy = {
        description = "Permissions required for T2 Bods EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/sap/bods/t2/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*",
            ]
          }
        ]
      }
      Ec2T2ReportingPolicy = {
        description = "Permissions required for T2 reporting EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/sap/bip/t2/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*",
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
              "arn:aws:elasticloadbalancing:*:*:listener-rule/app/public-lb/*",
            ]
          }
        ]
      }
    }

    lbs = {
      public = merge(local.lbs.public, {
        instance_target_groups = {
          t2-onr-bods-http28080 = merge(local.lbs.public.instance_target_groups.http28080, {
            attachments = [
              { ec2_instance_name = "t2-onr-bods-1" },
              # { ec2_instance_name = "t2-onr-bods-2" },
            ]
          })
          t2-onr-web-http-7777 = merge(local.lbs.public.instance_target_groups.http-7777, {
            attachments = [
              { ec2_instance_name = "t2-onr-web-1" },
            ]
          })
        }
        listeners = merge(local.lbs.public.listeners, {
          https = merge(local.lbs.public.listeners.https, {
            alarm_target_group_names = []
            rules = {
              t2-onr-bods-http28080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-onr-bods-http28080"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t2-bods.test.reporting.oasys.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t2-onr-web-http-7777 = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-onr-web-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t2.test.reporting.oasys.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })
        })
      })
    }

    patch_manager = {
      patch_schedules = {
        weds1500  = "cron(00 15 ? * WED *)" # 3pm wed 
        thurs1500 = "cron(00 15 ? * THU *)" # 3pm thu
        manual    = "cron(00 21 31 2 ? *)"  # 9pm 31 feb e.g. impossible date to allow for manual patching of otherwise enrolled instances
      }
      maintenance_window_duration = 2 # 4 for prod
      maintenance_window_cutoff   = 1 # 2 for prod
      patch_classifications = {
        REDHAT_ENTERPRISE_LINUX = ["Security", "Bugfix"] # Linux Options=(Security,Bugfix,Enhancement,Recommended,Newpackage)
        WINDOWS                 = ["SecurityUpdates", "CriticalUpdates"]
      }
    }

    route53_zones = {
      "test.reporting.oasys.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "t2", type = "A", lbs_map_key = "public" },
          { name = "t2-bods", type = "A", lbs_map_key = "public" },
        ],
      }
    }

    secretsmanager_secrets = {
      "/sap/bods/t2"             = local.secretsmanager_secrets.bods
      "/sap/bip/t2"              = local.secretsmanager_secrets.bip
      "/oracle/database/T2BOSYS" = local.secretsmanager_secrets.db
      "/oracle/database/T2BOAUD" = local.secretsmanager_secrets.db
    }
  }
}
