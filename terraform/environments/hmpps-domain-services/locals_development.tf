locals {

  baseline_presets_development = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "hmpps-domain-services-development"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_development = {

    acm_certificates = {
      remote_desktop_wildcard_cert = {
        cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name              = "*.development.hmpps-domain.service.justice.gov.uk"
        subject_alternate_names = [
          "*.hmpps-domain-services.hmpps-development.modernisation-platform.service.justice.gov.uk",
        ]
        tags = {
          description = "wildcard cert for hmpps domain load balancer"
        }
      }
    }

    ec2_autoscaling_groups = {
      dev-rhel85 = merge(local.ec2_autoscaling_groups.base_linux, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.base_linux.autoscaling_group, {
          # clean up Computer and DNS entry from azure.noms.root domain before using
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.base_linux.config, {
          ami_name = "base_rhel_8_5*"
        })
        instance = merge(local.ec2_autoscaling_groups.base_linux.instance, {
          instance_type = "t3.medium"
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.base_linux.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.base_linux.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.base_linux.tags, {
          ami         = "rhel_8_5"
          description = "RHEL 8.5 instance for testing domain join and patching"
          domain-name = "azure.noms.root"
        })
      })

      dev-win-2012 = merge(local.ec2_autoscaling_groups.base_windows, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.base_windows.autoscaling_group, {
          # clean up Computer and DNS entry from azure.noms.root domain before using
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.base_windows.config, {
          ami_name = "base_windows_server_2012_r2_release*"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
        }
        instance = merge(local.ec2_autoscaling_groups.base_windows.instance, {
          instance_type = "t3.medium"
        })
        tags = merge(local.ec2_autoscaling_groups.base_windows.tags, {
          description = "Windows Server 2012 instance for testing domain join and patching"
          domain-name = "azure.noms.root"
        })
      })

      dev-win-2022 = merge(local.ec2_autoscaling_groups.base_windows, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.base_windows.autoscaling_group, {
          # clean up Computer and DNS entry from azure.noms.root domain before using
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.base_windows.config, {
          ami_name = "hmpps_windows_server_2022_release_2024-*"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        instance = merge(local.ec2_autoscaling_groups.base_windows.instance, {
          instance_type = "t3.medium"
        })
        tags = merge(local.ec2_autoscaling_groups.base_windows.tags, {
          description = "Windows Server 2022 instance for testing domain join and patching"
          domain-name = "azure.noms.root"
        })
      })
    }

    ec2_instances = {
      dev-jump2022-1 = merge(local.ec2_instances.jumpserver, {
        config = merge(local.ec2_instances.jumpserver.config, {
          ami_name          = "hmpps_windows_server_2022_release_2025-01-02T00-00-40.487Z"
          availability_zone = "eu-west-2a"

          user_data_raw = base64encode(templatefile(
            "../../modules/baseline_presets/ec2-user-data/user-data-pwsh.yaml.tftpl", {
              branch = "TM-1849/sap-bip-client-install"
            }
          ))
        })
        instance = merge(local.ec2_instances.jumpserver.instance, {
          instance_type = "t3.large"
          tags = {
            patch-manager = "group1"
          }
        })
        tags = merge(local.ec2_instances.jumpserver.tags, {
          domain-name              = "azure.noms.root"
          gha-jumpserver-startstop = "test"
          instance-scheduling      = "skip-scheduling"
        })
      })
    }

    lbs = {
      public = merge(local.lbs.public, {
        instance_target_groups = {
          http1 = merge(local.lbs.public.instance_target_groups.http, {
            attachments = [
            ]
          })
          https1 = merge(local.lbs.public.instance_target_groups.https, {
            attachments = [
            ]
          })
        }
        listeners = merge(local.lbs.public.listeners, {
          https = merge(local.lbs.public.listeners.https, {
            rules = {
            }
          })
        })
      })
    }

    patch_manager = {
      patch_schedules = {
        group1 = "cron(50 06 ? * WED *)" # 6:50am wed to work around the overnight shutdown
        group2 = "cron(50 06 ? * THU *)" # 6:50am thu, see patch-manager.tf for approval_days config
      }
      maintenance_window_duration = 2 # 4 for prod
      maintenance_window_cutoff   = 1 # 2 for prod
      patch_classifications = {
        # REDHAT_ENTERPRISE_LINUX = ["Security", "Bugfix"] # Linux Options=(Security,Bugfix,Enhancement,Recommended,Newpackage)
        WINDOWS = ["SecurityUpdates", "CriticalUpdates", "UpdateRollups"] # Windows Options=CriticalUpdates,SecurityUpdates,DefinitionUpdates,Drivers,FeaturePacks,ServicePacks,Tools,UpdateRollups,Updates,Upgrades
      }
    }

    route53_zones = {
      "development.hmpps-domain.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "rdgateway1", type = "A", lbs_map_key = "public" },
          { name = "rdweb1", type = "A", lbs_map_key = "public" },
        ]
      }
    }
  }
}
