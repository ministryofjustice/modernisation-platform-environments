locals {

  lb_maintenance_message_test = {
    maintenance_title   = "Remote Desktop Environment Not Started"
    maintenance_message = "This environment is available during working hours 7am-10pm Please contact <a href=\"https://moj.enterprise.slack.com/archives/C6D94J81E\">#ask-digital-studio-ops</a> slack channel if environment is unexpectedly down"
  }

  baseline_presets_test = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "hmpps-domain-services-test"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_test = {

    acm_certificates = {
      remote_desktop_wildcard_cert = {
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "modernisation-platform.service.justice.gov.uk"
        external_validation_records_created = true
        subject_alternate_names = [
          "*.hmpps-domain-services.hmpps-test.modernisation-platform.service.justice.gov.uk",
          "*.test.hmpps-domain.service.justice.gov.uk",
          "hmppgw1.justice.gov.uk",
          "*.hmppgw1.justice.gov.uk",
        ]
        tags = {
          description = "wildcard cert for hmpps domain load balancer"
        }
      }
      remote_desktop_wildcard_cert_v2 = {
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "*.test.hmpps-domain.service.justice.gov.uk" # was "modernisation-platform.service.justice.gov.uk" # nomis ref: "*.test.nomis.service.justice.gov.uk" usage: rdgateway1.test.hmpps-domain.service.justice.gov.uk
        subject_alternate_names = [
          "*.hmpps-domain-services.hmpps-test.modernisation-platform.service.justice.gov.uk",
        ]
        tags = {
          description = "wildcard cert for hmpps domain load balancer"
        }
      }      
    }

    cloudwatch_dashboards = {
      "CloudWatch-Default" = {
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          module.baseline_presets.cloudwatch_dashboard_widget_groups.lb,
          local.cloudwatch_dashboard_widget_groups.all_ec2,
          local.cloudwatch_dashboard_widget_groups.jump,
          local.cloudwatch_dashboard_widget_groups.rdgateway,
          local.cloudwatch_dashboard_widget_groups.rdservices,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ssm_command,
        ]
      }
    }

    ec2_autoscaling_groups = {
      test-rhel85 = merge(local.ec2_autoscaling_groups.base_linux, {
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

      test-win-2012 = merge(local.ec2_autoscaling_groups.base_windows, {
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
          description = "Windows Server 2012 for connecting to Azure domain"
          domain-name = "azure.noms.root"
        })
      })

      test-win-2022 = merge(local.ec2_autoscaling_groups.base_windows, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.base_windows.autoscaling_group, {
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
      # NOTE: next rebuild do this as an ASG
      test-rdgw-1-a = merge(local.ec2_instances.rdgw, {
        config = merge(local.ec2_instances.rdgw.config, {
          availability_zone = "eu-west-2a"
        })
        instance = merge(local.ec2_instances.rdgw.instance, {
          tags = {
            patch-manager = "group1"
          }
        })
        tags = merge(local.ec2_instances.rdgw.tags, {
          description              = "Remote Desktop Gateway for azure.noms.root domain"
          domain-name              = "azure.noms.root"
          gha-jumpserver-startstop = "test"
          instance-scheduling      = "skip-scheduling"
        })
      })

      t1-jump2022-1 = merge(local.ec2_instances.jumpserver, {
        config = merge(local.ec2_instances.jumpserver.config, {
          ami_name          = "hmpps_windows_server_2022_release_2025-01-02T00-00-40.487Z"
          availability_zone = "eu-west-2a"
        })
        instance = merge(local.ec2_instances.jumpserver.instance, {
          instance_type = "r6i.large"
          tags = {
            patch-manager = "group2"
          }
        })
        tags = merge(local.ec2_instances.jumpserver.tags, {
          domain-name              = "azure.noms.root"
          gha-jumpserver-startstop = "test"
          instance-scheduling      = "skip-scheduling"
        })
      })

      test-rds-1-a = merge(local.ec2_instances.rds, {
        config = merge(local.ec2_instances.rds.config, {
          ami_name          = "hmpps_windows_server_2022_release_2025-04-02T00-00-40.543Z"
          availability_zone = "eu-west-2a"
        })
        instance = merge(local.ec2_instances.rds.instance, {
          tags = {
            patch-manager = "group2"
          }
        })
        tags = merge(local.ec2_instances.rds.tags, {
          domain-name              = "azure.noms.root"
          gha-jumpserver-startstop = "test"
          instance-scheduling      = "skip-scheduling"
          service-user             = "svc_rds"
        })
      })
    }

    lbs = {
      public = merge(local.lbs.public, {
        instance_target_groups = {
          test-rdgw-1-http = merge(local.lbs.public.instance_target_groups.http, {
            attachments = [
              { ec2_instance_name = "test-rdgw-1-a" },
            ]
          })
          test-rds-1-https = merge(local.lbs.public.instance_target_groups.https, {
            attachments = [
              { ec2_instance_name = "test-rds-1-a" },
            ]
          })
        }
        listeners = merge(local.lbs.public.listeners, {
          https = merge(local.lbs.public.listeners.https, {
            alarm_target_group_names = [
              "test-rdgw-1-http",
              "test-rds-1-https",
            ]
            certificate_names_or_arns = ["remote_desktop_wildcard_cert"]
            rules = {
              test-rdgw-1-http = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "test-rdgw-1-http"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "rdgateway1.test.hmpps-domain.service.justice.gov.uk",
                      "hmppgw1.justice.gov.uk",
                    ]
                  }
                }]
              }
              test-rds-1-https = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "test-rds-1-https"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "rdweb1.test.hmpps-domain.service.justice.gov.uk"
                    ]
                  }
                }]
              }
              maintenance = {
                priority = 999
                actions = [{
                  type = "fixed-response"
                  fixed_response = {
                    content_type = "text/html"
                    message_body = templatefile("templates/maintenance.html.tftpl", local.lb_maintenance_message_test)
                    status_code  = "200"
                  }
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "maintenance.test.hmpps-domain.service.justice.gov.uk",
                      "rdweb1.test.hmpps-domain.service.justice.gov.uk"
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
        group1 = "cron(50 06 ? * WED *)" # 6:50am wed to work around the overnight shutdown
        group2 = "cron(50 06 ? * THU *)" # 6:50am thu, see patch-manager.tf for approval_days config
        manual = "cron(00 21 31 2 ? *)"  # 9pm 31 feb e.g. impossible date to allow for manual patching of otherwise enrolled instances
      }
      maintenance_window_duration = 2 # 4 for prod
      maintenance_window_cutoff   = 1 # 2 for prod
      patch_classifications = {
        REDHAT_ENTERPRISE_LINUX = ["Security", "Bugfix"]                 # Linux Options=Security,Bugfix,Enhancement,Recommended,Newpackage
        WINDOWS                 = ["SecurityUpdates", "CriticalUpdates", "UpdateRollups"] # Windows Options=CriticalUpdates,SecurityUpdates,DefinitionUpdates,Drivers,FeaturePacks,ServicePacks,Tools,UpdateRollups,Updates,Upgrades
      }
    }

    schedule_alarms_lambda = {
      alarm_patterns = [
        "public-https-*-unhealthy-load-balancer-host",
        "*-instance-or-cloudwatch-agent-stopped",
      ]
      end_time = "07:00"
    }

    route53_zones = {
      "test.hmpps-domain.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "maintenance", type = "A", lbs_map_key = "public" },
          { name = "rdgateway1", type = "A", lbs_map_key = "public" },
          { name = "rdweb1", type = "A", lbs_map_key = "public" },
        ]
      }
    }

    secretsmanager_secrets = {
      "/microsoft/AD/azure.noms.root" = local.secretsmanager_secrets.domain
    }
  }
}
