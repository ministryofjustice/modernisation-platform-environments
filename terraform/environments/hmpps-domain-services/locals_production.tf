locals {

  lb_maintenance_message_production = {
    maintenance_title   = "Remote Desktop Environment Maintenance Window"
    maintenance_message = "Remote Desktop Environment is currently unavailable due to planned maintenance. Please try again later"
  }

  baseline_presets_production = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "hmpps-domain-services-production"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_production = {

    acm_certificates = {

      remote_desktop_wildcard_and_planetfm_cert_v2 = {
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "modernisation-platform.service.justice.gov.uk"
        external_validation_records_created = true
        subject_alternate_names = [
          "*.hmpps-domain-services.hmpps-production.modernisation-platform.service.justice.gov.uk",
          "*.hmpps-domain.service.justice.gov.uk",
          "hmpps-az-gw1.justice.gov.uk",
          "*.hmpps-az-gw1.justice.gov.uk",
          "*.planetfm.service.justice.gov.uk",
          "cafmtx.az.justice.gov.uk",
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

    ec2_instances = {

      pd-jump2022-1 = merge(local.ec2_instances.jumpserver, {
        config = merge(local.ec2_instances.jumpserver.config, {
          ami_name          = "hmpps_windows_server_2022_release_2025-01-02T00-00-40.487Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.jumpserver.config.instance_profile_policies, [
            "Ec2GFSLSecretPolicy"
          ])
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 120 }
        }
        instance = merge(local.ec2_instances.jumpserver.instance, {
          instance_type = "r6i.large"
          tags = {
            patch-manager = "group1"
          }
        })
        tags = merge(local.ec2_instances.jumpserver.tags, {
          domain-name              = "azure.hmpp.root"
          gha-jumpserver-startstop = "production"
        })
      })

      pd-rdgw-1-a = merge(local.ec2_instances.rdgw, {
        config = merge(local.ec2_instances.rdgw.config, {
          availability_zone = "eu-west-2a"
        })
        instance = merge(local.ec2_instances.rdgw.instance, {
          tags = {
            patch-manager = "group1"
          }
        })
        tags = merge(local.ec2_instances.rdgw.tags, {
          description              = "Remote Desktop Gateway for azure.hmpp.root domain"
          domain-name              = "azure.hmpp.root"
          gha-jumpserver-startstop = "production"
          update-ssm-agent         = "patchgroup1"
        })
      })

      pd-rdgw-1-b = merge(local.ec2_instances.rdgw, {
        config = merge(local.ec2_instances.rdgw.config, {
          availability_zone = "eu-west-2b"
        })
        instance = merge(local.ec2_instances.rdgw.instance, {
          tags = {
            patch-manager = "group2"
          }
        })
        tags = merge(local.ec2_instances.rdgw.tags, {
          description              = "Remote Desktop Gateway for azure.hmpp.root domain"
          domain-name              = "azure.hmpp.root"
          gha-jumpserver-startstop = "production"
          update-ssm-agent         = "patchgroup2"
        })
      })

      pd-rds-1-a = merge(local.ec2_instances.rds, {
        config = merge(local.ec2_instances.rds.config, {
          availability_zone = "eu-west-2a"
        })
        instance = merge(local.ec2_instances.rds.instance, {
          instance_type = "t3.large"
          tags = {
            patch-manager = "group2"
          }
        })
        tags = merge(local.ec2_instances.rds.tags, {
          description              = "Remote Desktop Services for azure.hmpp.root domain"
          domain-name              = "azure.hmpp.root"
          gha-jumpserver-startstop = "production"
          service-user             = "svc_rds"
        })
      })
    }

    iam_policies = {
      Ec2GFSLSecretPolicy = {
        description = "Permissions required to access GFSL secrets"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/GFSL/*",
            ]
          }
        ]
      }
    }

    lbs = {
      public = merge(local.lbs.public, {
        instance_target_groups = {
          pd-rdgw-1-http = merge(local.lbs.public.instance_target_groups.http, {
            attachments = [
              { ec2_instance_name = "pd-rdgw-1-a" },
              { ec2_instance_name = "pd-rdgw-1-b" },
            ]
          })
          pd-rds-1-https = merge(local.lbs.public.instance_target_groups.https, {
            attachments = [
              { ec2_instance_name = "pd-rds-1-a" },
            ]
          })
        }
        listeners = merge(local.lbs.public.listeners, {
          https = merge(local.lbs.public.listeners.https, {
            certificate_names_or_arns = ["remote_desktop_wildcard_and_planetfm_cert_v2"]

            alarm_target_group_names = [
              "pd-rdgw-1-http",
              "pd-rds-1-https",
            ]

            rules = {
              pd-rdgw-1-http = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "pd-rdgw-1-http"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "rdgateway1.hmpps-domain.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              pd-rds-1-https = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "pd-rds-1-https"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "rdweb1.hmpps-domain.service.justice.gov.uk",
                      "cafmtx.planetfm.service.justice.gov.uk",
                      "cafmtx.az.justice.gov.uk",
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
                    message_body = templatefile("templates/maintenance.html.tftpl", local.lb_maintenance_message_production)
                    status_code  = "200"
                  }
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "maintenance.hmpps-domain.service.justice.gov.uk",
                      "rdweb1.hmpps-domain.service.justice.gov.uk",
                      "cafmtx.planetfm.service.justice.gov.uk",
                      "cafmtx.az.justice.gov.uk",
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
        group1 = "cron(00 03 ? * WED *)"
        group2 = "cron(00 03 ? * THU *)"
      }
      maintenance_window_duration = 4
      maintenance_window_cutoff   = 2
      patch_classifications = {
        # REDHAT_ENTERPRISE_LINUX = ["Security", "Bugfix"] # Linux Options=(Security,Bugfix,Enhancement,Recommended,Newpackage)
        WINDOWS = ["SecurityUpdates", "CriticalUpdates", "UpdateRollups", "ServicePacks", "Updates"] # Windows Options=CriticalUpdates,SecurityUpdates,DefinitionUpdates,Drivers,FeaturePacks,ServicePacks,Tools,UpdateRollups,Updates,Upgrades
      }
    }


    route53_zones = {
      "hmpps-domain.service.justice.gov.uk" = {
        records = [
          { name = "development", type = "NS", ttl = "86400", records = ["ns-1447.awsdns-52.org", "ns-1826.awsdns-36.co.uk", "ns-1022.awsdns-63.net", "ns-418.awsdns-52.com", ] },
          { name = "test", type = "NS", ttl = "86400", records = ["ns-134.awsdns-16.com", "ns-1426.awsdns-50.org", "ns-1934.awsdns-49.co.uk", "ns-927.awsdns-51.net", ] },
          { name = "preproduction", type = "NS", ttl = "86400", records = ["ns-1509.awsdns-60.org", "ns-1925.awsdns-48.co.uk", "ns-216.awsdns-27.com", "ns-753.awsdns-30.net", ] },
          { name = "smtp", type = "A", ttl = 300, records = ["10.180.104.100", "10.180.105.100"] } # smtp.internal.network.justice.gov.uk not publicly resolvable
        ]

        lb_alias_records = [
          { name = "maintenance", type = "A", lbs_map_key = "public" },
          { name = "rdgateway1", type = "A", lbs_map_key = "public" },
          { name = "rdweb1", type = "A", lbs_map_key = "public" },
        ]
      }
      "az.justice.gov.uk" = {
        records = [
          # validation records
          # { name = "_bc45f2d6d9bf486b641716271dfbe56c.cafmtx", type = "CNAME", ttl = 86400, records = ["_1aa4c911695fe4b8da33b57c2405112d.sdgjtdhdhz.acm-validations.aws"] }, #this is auto populating
          # cname records
          { name = "cafmtx", type = "CNAME", ttl = "86400", records = ["cafmtx.planetfm.service.justice.gov.uk"] },
          # NS records
          { name = "bridge-oasys", type = "NS", ttl = "86400", records = ["ns-3.awsdns-00.com", "ns-1301.awsdns-34.org", "ns-977.awsdns-58.net", "ns-1726.awsdns-23.co.uk"] },
          { name = "cafmtrainweb", type = "NS", ttl = "86400", records = ["ns-1710.awsdns-21.co.uk", "ns-153.awsdns-19.com", "ns-712.awsdns-25.net", "ns-1400.awsdns-47.org"] },
          { name = "cafmwebx2", type = "NS", ttl = "86400", records = ["ns-588.awsdns-09.net", "ns-509.awsdns-63.com", "ns-1218.awsdns-24.org", "ns-1760.awsdns-28.co.uk"] },
          { name = "csr", type = "NS", ttl = "86400", records = ["ns-1847.awsdns-38.co.uk", "ns-207.awsdns-25.com", "ns-1259.awsdns-29.org", "ns-934.awsdns-52.net"] },
          { name = "nomis", type = "NS", ttl = "86400", records = ["ns-1694.awsdns-19.co.uk", "ns-1405.awsdns-47.org", "ns-949.awsdns-54.net", "ns-403.awsdns-50.com"] },
          { name = "oasys", type = "NS", ttl = "86400", records = ["ns-1633.awsdns-12.co.uk", "ns-1387.awsdns-45.org", "ns-509.awsdns-63.com", "ns-800.awsdns-36.net"] },
          { name = "p-oasys", type = "NS", ttl = "86400", records = ["ns-1956.awsdns-52.co.uk", "ns-639.awsdns-15.net", "ns-110.awsdns-13.com", "ns-1252.awsdns-28.org"] },
          { name = "pp-nomis", type = "NS", ttl = "86400", records = ["ns-896.awsdns-48.net", "ns-1970.awsdns-54.co.uk", "ns-418.awsdns-52.com", "ns-1209.awsdns-23.org"] },
          { name = "pp-cafmwebx", type = "NS", ttl = "86400", records = ["ns-1428.awsdns-50.org", "ns-658.awsdns-18.net", "ns-1604.awsdns-08.co.uk", "ns-73.awsdns-09.com"] },
          { name = "pp-oasys", type = "NS", ttl = "86400", records = ["ns-360.awsdns-45.com", "ns-1408.awsdns-48.org", "ns-1717.awsdns-22.co.uk", "ns-1012.awsdns-62.net"] },
          # A records
          { name = "prs", type = "A", ttl = 3600, records = ["10.40.10.132"] }
        ]

        lb_alias_records = []
      }
    }

    secretsmanager_secrets = {
      "/microsoft/AD/azure.hmpp.root" = local.secretsmanager_secrets.domain
      "/GFSL"                         = local.secretsmanager_secrets.gfsl
      "/DSO"                          = local.secretsmanager_secrets.dso
    }
  }
}
