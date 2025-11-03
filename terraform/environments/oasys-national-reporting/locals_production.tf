locals {

  baseline_presets_production = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "oasys-national-reporting-production"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_production = {

    acm_certificates = {
      oasys_national_reporting_wildcard_cert = {
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "modernisation-platform.service.justice.gov.uk"
        external_validation_records_created = true
        subject_alternate_names = [
          "*.oasys-national-reporting.hmpps-production.modernisation-platform.service.justice.gov.uk",
          "reporting.oasys.service.justice.gov.uk",
          "*.reporting.oasys.service.justice.gov.uk",
          "onr.oasys.az.justice.gov.uk",
        ]
        tags = {
          description = "Wildcard certificate for the ${local.environment} environment"
        }
      }
    }

    ec2_instances = {
      pd-onr-bods-1 = merge(local.ec2_instances.bods, {
        config = merge(local.ec2_instances.bods.config, {
          ami_name          = "hmpps_windows_server_2019_release_2025-01-02T00-00-37.501Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bods.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bods.instance, {
          instance_type           = "r6i.2xlarge"
          disable_api_termination = true
        })
        tags = merge(local.ec2_instances.bods.tags, {
          oasys-national-reporting-environment = "pd"
          domain-name                          = "azure.hmpp.root"
        })
        cloudwatch_metric_alarms = merge(
          module.baseline_presets.cloudwatch_metric_alarms.ec2,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows,
          local.cloudwatch_metric_alarms.windows,
          local.cloudwatch_metric_alarms.bods_primary,
        )
      })

      pd-onr-bods-2 = merge(local.ec2_instances.bods, {
        config = merge(local.ec2_instances.bods.config, {
          ami_name          = "hmpps_windows_server_2019_release_2025-01-02T00-00-37.501Z"
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.bods.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bods.instance, {
          instance_type           = "r6i.2xlarge"
          disable_api_termination = true
        })
        tags = merge(local.ec2_instances.bods.tags, {
          oasys-national-reporting-environment = "pd"
          domain-name                          = "azure.hmpp.root"
        })
        cloudwatch_metric_alarms = merge(
          module.baseline_presets.cloudwatch_metric_alarms.ec2,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows,
          local.cloudwatch_metric_alarms.windows,
          local.cloudwatch_metric_alarms.bods_secondary,
        )
      })

      pd-onr-cms-1 = merge(local.ec2_instances.bip_cms, {
        config = merge(local.ec2_instances.bip_cms.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_cms.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip_cms.instance, {
          instance_type = "m6i.2xlarge"
        })
        user_data_cloud_init = merge(local.ec2_instances.bip_cms.user_data_cloud_init, {
          args = merge(local.ec2_instances.bip_cms.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.bip_cms.tags, {
          oasys-national-reporting-environment = "pd"
        })
      })

      pd-onr-cms-2 = merge(local.ec2_instances.bip_cms, {
        config = merge(local.ec2_instances.bip_cms.config, {
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.bip_cms.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip_cms.instance, {
          instance_type = "m6i.2xlarge"
        })
        user_data_cloud_init = merge(local.ec2_instances.bip_cms.user_data_cloud_init, {
          args = merge(local.ec2_instances.bip_cms.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.bip_cms.tags, {
          oasys-national-reporting-environment = "pd"
        })
      })

      pd-onr-web-1 = merge(local.ec2_instances.bip_web, {
        config = merge(local.ec2_instances.bip_web.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_web.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip_web.instance, {
          instance_type = "m6i.xlarge"
        })
        user_data_cloud_init = merge(local.ec2_instances.bip_web.user_data_cloud_init, {
          args = merge(local.ec2_instances.bip_web.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.bip_web.tags, {
          oasys-national-reporting-environment = "pd"
        })
      })

      pd-onr-web-2 = merge(local.ec2_instances.bip_web, {
        config = merge(local.ec2_instances.bip_web.config, {
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.bip_web.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip_web.instance, {
          instance_type = "m6i.xlarge"
        })
        user_data_cloud_init = merge(local.ec2_instances.bip_web.user_data_cloud_init, {
          args = merge(local.ec2_instances.bip_web.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.bip_web.tags, {
          oasys-national-reporting-environment = "pd"
        })
      })
    }

    efs = {
      pd-onr-sap-share = {
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
          lifecycle_policy = {
            transition_to_ia = "AFTER_30_DAYS"
          }
        }
        mount_targets = [{
          subnet_name        = "private"
          availability_zones = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
          security_groups    = ["efs"]
        }]
        tags = {
          backup      = "false"
          backup-plan = "daily-and-weekly"
        }
      }
    }

    fsx_windows = {

      pd-bods-win-share = {
        automatic_backup_retention_days = 0
        deployment_type                 = "MULTI_AZ_1"
        preferred_availability_zone     = "eu-west-2a"
        security_groups                 = ["bods"]
        skip_final_backup               = true
        storage_capacity                = 600
        throughput_capacity             = 8

        subnets = [
          {
            name               = "private"
            availability_zones = ["eu-west-2a", "eu-west-2b"]
          }
        ]

        self_managed_active_directory = {
          dns_ips = flatten([
            module.ip_addresses.mp_ips.ad_fixngo_hmpp_domain_controllers,
          ])
          domain_name                      = "azure.hmpp.root"
          username                         = "svc_fsx_windows"
          password_secret_name             = "/sap/bods/pd/passwords"
          file_system_administrators_group = "Domain Join"
        }
        tags = {
          backup = true
        }
      }
    }

    iam_policies = {
      Ec2SecretPolicy = {
        description = "Permissions required for secret value access by instances"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/sap/bods/pd/*",
              "arn:aws:secretsmanager:*:*:secret:/sap/bip/pd/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*",
            ]
          }
        ]
      }
    }

    lbs = {
      public = merge(local.lbs.public, {
        instance_target_groups = {
          pd-onr-bods-http28080 = merge(local.lbs.public.instance_target_groups.http28080, {
            attachments = [
              { ec2_instance_name = "pd-onr-bods-1" },
            ]
          })
          pd-onr-web-http-7777 = merge(local.lbs.public.instance_target_groups.http-7777, {
            attachments = [
              { ec2_instance_name = "pd-onr-web-1" },
              { ec2_instance_name = "pd-onr-web-2" },
            ]
          })
        }
        listeners = merge(local.lbs.public.listeners, {
          https = merge(local.lbs.public.listeners.https, {
            alarm_target_group_names = []
            rules = {
              pd-onr-bods-http28080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "pd-onr-bods-http28080"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "bods.reporting.oasys.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              pd-onr-web-http-7777 = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "pd-onr-web-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "reporting.oasys.service.justice.gov.uk",
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
        manual = "cron(00 21 31 2 ? *)" # 9pm 31 feb e.g. impossible date to allow for manual patching of otherwise enrolled instances
      }
      maintenance_window_duration = 2 # 4 for prod
      maintenance_window_cutoff   = 1 # 2 for prod
      patch_classifications = {
        # REDHAT_ENTERPRISE_LINUX = ["Security", "Bugfix"] # Linux Options=(Security,Bugfix,Enhancement,Recommended,Newpackage)
        WINDOWS = ["SecurityUpdates", "CriticalUpdates"]
      }
    }

    route53_zones = {
      "reporting.oasys.service.justice.gov.uk" = {
        ns_records = [
          # use this if NS records can be pulled from terrafrom, otherwise use records variable
          { name = "production", ttl = "86400", zone_name = "production.reporting.oasys.service.justice.gov.uk" }
        ]
        records = [
          { name = "development", type = "NS", ttl = "86400", records = ["ns-1298.awsdns-34.org", "ns-1591.awsdns-06.co.uk", "ns-317.awsdns-39.com", "ns-531.awsdns-02.net"] },
          { name = "test", type = "NS", ttl = "86000", records = ["ns-1440.awsdns-52.org", "ns-1823.awsdns-35.co.uk", "ns-43.awsdns-05.com", "ns-893.awsdns-47.net"] },
          { name = "preproduction", type = "NS", ttl = "86400", records = ["ns-1161.awsdns-17.org", "ns-2014.awsdns-59.co.uk", "ns-487.awsdns-60.com", "ns-919.awsdns-50.net"] },
        ]
        lb_alias_records = [
          { name = "", type = "A", lbs_map_key = "public" },
          { name = "bods", type = "A", lbs_map_key = "public" }
        ],
      }
      "production.reporting.oasys.service.justice.gov.uk" = {
      }
    }
    secretsmanager_secrets = {
      "/sap/bods/pd"             = local.secretsmanager_secrets.bods
      "/sap/bip/pd"              = local.secretsmanager_secrets.bip
      "/oracle/database/PDBOSYS" = local.secretsmanager_secrets.db
      "/oracle/database/PDBOAUD" = local.secretsmanager_secrets.db
    }
  }
}
