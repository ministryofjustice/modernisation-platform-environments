locals {

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
        WINDOWS = ["SecurityUpdates", "CriticalUpdates"]
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
          { name = "rdgateway1", type = "A", lbs_map_key = "public" },
          { name = "rdweb1", type = "A", lbs_map_key = "public" },
        ]
      }
    }

    secretsmanager_secrets = {
      "/microsoft/AD/azure.hmpp.root" = local.secretsmanager_secrets.domain
      "/GFSL"                         = local.secretsmanager_secrets.gfsl
    }
  }
}
