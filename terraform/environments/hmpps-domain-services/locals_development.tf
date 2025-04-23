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
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "modernisation-platform.service.justice.gov.uk"
        external_validation_records_created = true
        subject_alternate_names = [
          "*.hmpps-domain-services.hmpps-development.modernisation-platform.service.justice.gov.uk",
          "*.development.hmpps-domain.service.justice.gov.uk",
          "hmppgw2.justice.gov.uk",
          "*.hmppgw2.justice.gov.uk",
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
        group1 = "cron(00 06 ? * WED *)" # 3am wed for prod for non-prod env's we have to work around the overnight shutdown  
        group2 = "cron(00 06 ? * THU *)" # 3am thu for prod
      }
      maintenance_window_duration = 2 # 4 for prod
      maintenance_window_cutoff   = 1 # 2 for prod
      patch_classifications = {
        # REDHAT_ENTERPRISE_LINUX = ["Security", "Bugfix"] # Linux Options=(Security,Bugfix,Enhancement,Recommended,Newpackage)
        WINDOWS = ["SecurityUpdates", "CriticalUpdates"]
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
