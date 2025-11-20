locals {

  lb_maintenance_message_preproduction = {
    maintenance_title   = "Remote Desktop Environment Not Started"
    maintenance_message = "Please contact <a href=\"https://moj.enterprise.slack.com/archives/C6D94J81E\">#ask-digital-studio-ops</a> slack channel if environment is unexpectedly down"
  }

  baseline_presets_preproduction = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "hmpps-domain-services-preproduction"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_preproduction = {

    acm_certificates = {
      remote_desktop_and_planetfm_wildcard_cert = {
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "modernisation-platform.service.justice.gov.uk"
        external_validation_records_created = true
        subject_alternate_names = [
          "*.hmpps-domain-services.hmpps-preproduction.modernisation-platform.service.justice.gov.uk",
          "*.preproduction.hmpps-domain.service.justice.gov.uk",
          "*.pp.planetfm.service.justice.gov.uk",
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
      dev-win-2022 = merge(local.ec2_autoscaling_groups.base_windows, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.base_windows.autoscaling_group, {
          # clean up Computer and DNS entry from azure.hmpp.root domain before using
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
          domain-name = "azure.hmpp.root"
        })
      })

      dev-rhel85 = merge(local.ec2_autoscaling_groups.base_linux, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.base_linux.autoscaling_group, {
          # clean up Computer and DNS entry from azure.hmpp.root domain before using
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
          domain-name = "azure.hmpp.root"
        })
      })
    }

    ec2_instances = {

      pp-jump2022-1 = merge(local.ec2_instances.jumpserver, {
        config = merge(local.ec2_instances.jumpserver.config, {
          ami_name          = "hmpps_windows_server_2022_release_2025-01-02T00-00-40.487Z"
          availability_zone = "eu-west-2a"
        })
        instance = merge(local.ec2_instances.jumpserver.instance, {
          instance_type = "r6i.xlarge"
          tags = {
            patch-manager = "group2"
          }
        })
        tags = merge(local.ec2_instances.jumpserver.tags, {
          domain-name              = "azure.hmpp.root"
          gha-jumpserver-startstop = "preproduction"
          instance-scheduling      = "skip-scheduling"
        })
      })

      pp-rdgw-1-a = merge(local.ec2_instances.rdgw, {
        config = merge(local.ec2_instances.rdgw.config, {
          availability_zone = "eu-west-2a"
        })
        instance = merge(local.ec2_instances.rdgw.instance, {
          tags = {
            backup-plan   = "daily-and-weekly"
            patch-manager = "group1"
          }
        })
        tags = merge(local.ec2_instances.rdgw.tags, {
          description              = "Remote Desktop Gateway for azure.hmpp.root domain"
          domain-name              = "azure.hmpp.root"
          gha-jumpserver-startstop = "preproduction"
          instance-scheduling      = "skip-scheduling"
        })
      })

      pp-rds-1-a = merge(local.ec2_instances.rds, {
        config = merge(local.ec2_instances.rds.config, {
          availability_zone = "eu-west-2a"
        })
        instance = merge(local.ec2_instances.rds.instance, {
          tags = {
            patch-manager = "group2"
          }
        })
        tags = merge(local.ec2_instances.rds.tags, {
          description              = "Remote Desktop Services for azure.hmpp.root domain"
          domain-name              = "azure.hmpp.root"
          gha-jumpserver-startstop = "preproduction"
          service-user             = "svc_rds"
          instance-scheduling      = "skip-scheduling"
        })
      })
    }

    lbs = {
      public = merge(local.lbs.public, {
        instance_target_groups = {
          pp-rdgw-1-http = merge(local.lbs.public.instance_target_groups.http, {
            attachments = [
              { ec2_instance_name = "pp-rdgw-1-a" },
            ]
          })
          pp-rds-1-https = merge(local.lbs.public.instance_target_groups.https, {
            attachments = [
              { ec2_instance_name = "pp-rds-1-a" },
            ]
          })
        }
        listeners = merge(local.lbs.public.listeners, {
          https = merge(local.lbs.public.listeners.https, {
            alarm_target_group_names = [
              "pp-rdgw-1-http",
              "pp-rds-1-https",
            ]
            certificate_names_or_arns = ["remote_desktop_and_planetfm_wildcard_cert"]
            rules = {
              pp-rdgw-1-http = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "pp-rdgw-1-http"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "rdgateway1.preproduction.hmpps-domain.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              pp-rds-1-https = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "pp-rds-1-https"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "rdweb1.preproduction.hmpps-domain.service.justice.gov.uk",
                      "cafmtx.pp.planetfm.service.justice.gov.uk",
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
                    message_body = templatefile("templates/maintenance.html.tftpl", local.lb_maintenance_message_preproduction)
                    status_code  = "200"
                  }
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "maintenance.preproduction.hmpps-domain.service.justice.gov.uk",
                      "rdweb1.preproduction.hmpps-domain.service.justice.gov.uk",
                      "cafmtx.pp.planetfm.service.justice.gov.uk",
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

    schedule_alarms_lambda = {
      alarm_patterns = [
        "public-https-*-unhealthy-load-balancer-host",
        "*-instance-or-cloudwatch-agent-stopped",
      ]
      end_time = "07:00"
    }

    route53_zones = {
      "preproduction.hmpps-domain.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "maintenance", type = "A", lbs_map_key = "public" },
          { name = "rdgateway1", type = "A", lbs_map_key = "public" },
          { name = "rdweb1", type = "A", lbs_map_key = "public" },
        ]
      }
    }
  }
}
