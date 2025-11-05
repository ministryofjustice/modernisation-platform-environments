locals {

  baseline_presets_preproduction = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "oasys-national-reporting-preproduction"
        }
      }
    }
  }


  # please keep resources in alphabetical order
  baseline_preproduction = {

    acm_certificates = {
      oasys_national_reporting_wildcard_cert = {
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "modernisation-platform.service.justice.gov.uk"
        external_validation_records_created = true
        subject_alternate_names = [
          "*.oasys-national-reporting.hmpps-preproduction.modernisation-platform.service.justice.gov.uk",
          "preproduction.reporting.oasys.service.justice.gov.uk",
          "*.preproduction.reporting.oasys.service.justice.gov.uk",
          "onr.pp-oasys.az.justice.gov.uk",
        ]
        tags = {
          description = "Wildcard certificate for the preproduction environment"
        }
      }
    }

    efs = {
      pp-onr-sap-share = {
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

    # Instance Type Defaults for preproduction
    # instance_type_defaults = {
    #   web = "m6i.xlarge" # 4 vCPUs, 16GB RAM x 2 instances
    #   boe = "m4.2xlarge" # 8 vCPUs, 32GB RAM x 2 instances
    #   bods = "r6i.2xlarge" # 8 vCPUs, 61GB RAM x 1 instance: RAM == production instance to allow load-testing in preprod
    # }
    ec2_instances = {
      pp-onr-bods-1 = merge(local.ec2_instances.bods, {
        config = merge(local.ec2_instances.bods.config, {
          ami_name          = "hmpps_windows_server_2019_release_2024-10-02T00-00-37.793Z"
          availability_zone = "eu-west-2a"
          user_data_raw = base64encode(templatefile(
            "./templates/user-data-onr-bods-pwsh.yaml.tftpl", {
              branch = "main"
            }
          ))
          instance_profile_policies = concat(local.ec2_instances.bods.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
        })
        # IMPORTANT: EBS volume initialization, labelling, formatting was carried out manually on this instance. It was not automated so these ebs_volume settings are bespoke. Additional volumes should NOT be /dev/xvd* see the local.ec2_instances.bods.ebs_volumes setting for the correct device names.
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/xvdk" = { type = "gp3", size = 128 } # D:/ Temp
          "/dev/xvdl" = { type = "gp3", size = 128 } # E:/ App
          "/dev/xvdm" = { type = "gp3", size = 700 } # F:/ Storage
        }
        instance = merge(local.ec2_instances.bods.instance, {
          instance_type           = "r6i.2xlarge"
          disable_api_termination = true
          tags = merge(local.ec2_instances.bods.instance.tags, {
            patch-manager = "weds1500"
          })
        })
        tags = merge(local.ec2_instances.bods.tags, {
          oasys-national-reporting-environment = "pp"
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

      pp-onr-bods-2 = merge(local.ec2_instances.bods, {
        config = merge(local.ec2_instances.bods.config, {
          ami_name          = "hmpps_windows_server_2019_release_2025-07-02T00-00-37.630Z"
          availability_zone = "eu-west-2b"
          user_data_raw = base64encode(templatefile(
            "./templates/user-data-onr-bods-pwsh.yaml.tftpl", {
              branch = "main"
            }
          ))
          instance_profile_policies = concat(local.ec2_instances.bods.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bods.instance, {
          instance_type           = "r6i.2xlarge"
          disable_api_termination = false # swap to true once configured
          tags = merge(local.ec2_instances.bods.instance.tags, {
            patch-manager = "thurs1500"
          })
        })
        tags = merge(local.ec2_instances.bods.tags, {
          oasys-national-reporting-environment = "pp"
          domain-name                          = "azure.hmpp.root"
        })
        cloudwatch_metric_alarms = {} # swap with block below once configured
        # cloudwatch_metric_alarms = merge(
        #   module.baseline_presets.cloudwatch_metric_alarms.ec2,
        #   module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows,
        #   module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows,
        #   local.cloudwatch_metric_alarms.windows,
        #   local.cloudwatch_metric_alarms.bods_secondary,
        # )
      })

      pp-onr-cms-1 = merge(local.ec2_instances.bip_cms, {
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
          instance-scheduling                  = "skip-scheduling"
          oasys-national-reporting-environment = "pp"
        })
      })

      pp-onr-web-1 = merge(local.ec2_instances.bip_web, {
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
          instance-scheduling                  = "skip-scheduling"
          oasys-national-reporting-environment = "pp"
        })
      })

      # Temporary windows BIP server for migration only
      pp-win-bip-1 = merge(local.ec2_instances.windows_bip, {
        config = merge(local.ec2_instances.windows_bip.config, {
          ami_name          = "hmpps_windows_server_2022_release_2025-06-02T00-00-40.444Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.windows_bip.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
          user_data_raw = base64encode(templatefile(
            "./templates/user-data-onr-bip-pwsh.yaml.tftpl", {
              branch = "main"
            }
          ))
        })
        tags = merge(local.ec2_instances.windows_bip.tags, {
          oasys-national-reporting-environment = "pp"
          domain-name                          = "azure.hmpp.root"
        })
      })
    }

    fsx_windows = {

      pp-bods-win-share = {
        aliases                         = ["pp-onr-fs.azure.hmpp.root"]
        automatic_backup_retention_days = 0
        deployment_type                 = "SINGLE_AZ_1"
        security_groups                 = ["bods"]
        skip_final_backup               = true
        storage_capacity                = 600
        throughput_capacity             = 8

        subnets = [
          {
            name               = "private"
            availability_zones = ["eu-west-2a"]
          }
        ]

        self_managed_active_directory = {
          dns_ips = flatten([
            module.ip_addresses.mp_ips.ad_fixngo_hmpp_domain_controllers,
          ])
          domain_name                      = "azure.hmpp.root"
          username                         = "svc_fsx_windows"
          password_secret_name             = "/sap/bods/pp/passwords"
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
              "arn:aws:secretsmanager:*:*:secret:/sap/bods/pp/*",
              "arn:aws:secretsmanager:*:*:secret:/sap/bip/pp/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*",
            ]
          }
        ]
      }
    }

    lbs = {
      public = merge(local.lbs.public, {
        instance_target_groups = {
          pp-onr-bods-http28080 = merge(local.lbs.public.instance_target_groups.http28080, {
            attachments = [
              { ec2_instance_name = "pp-onr-bods-1" },
            ]
          })
          pp-onr-web-http-7777 = merge(local.lbs.public.instance_target_groups.http-7777, {
            attachments = [
              { ec2_instance_name = "pp-onr-web-1" },
            ]
          })
        }
        listeners = merge(local.lbs.public.listeners, {
          https = merge(local.lbs.public.listeners.https, {
            alarm_target_group_names = []
            rules = {
              pp-onr-bods-http28080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "pp-onr-bods-http28080"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "pp-bods.preproduction.reporting.oasys.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              pp-onr-web-http-7777 = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "pp-onr-web-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "preproduction.reporting.oasys.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })
        })
      })
    } # end of lbs

    patch_manager = {
      patch_schedules = {
        weds1500  = "cron(00 15 ? * WED *)" # 3pm wed 
        thurs1500 = "cron(00 15 ? * THU *)" # 3pm thu
        # manual    = "cron(00 21 31 2 ? *)"  # 9pm 31 feb e.g. impossible date to allow for manual patching of otherwise enrolled instances
      }
      maintenance_window_duration = 2 # 4 for prod
      maintenance_window_cutoff   = 1 # 2 for prod
      patch_classifications = {
        # REDHAT_ENTERPRISE_LINUX = ["Security", "Bugfix"] # Linux Options=(Security,Bugfix,Enhancement,Recommended,Newpackage)
        WINDOWS = ["SecurityUpdates", "CriticalUpdates"]
      }
    }

    route53_zones = {
      "preproduction.reporting.oasys.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "", type = "A", lbs_map_key = "public" },
          { name = "pp-bods", type = "A", lbs_map_key = "public" }
        ],
      }
    }

    secretsmanager_secrets = {
      "/sap/bods/pp"             = local.secretsmanager_secrets.bods
      "/sap/bip/pp"              = local.secretsmanager_secrets.bip
      "/oracle/database/PPBOSYS" = local.secretsmanager_secrets.db
      "/oracle/database/PPBOAUD" = local.secretsmanager_secrets.db
    }
  }
}
