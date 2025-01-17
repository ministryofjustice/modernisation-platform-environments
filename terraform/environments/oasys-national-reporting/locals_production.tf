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

    # Instance Type Defaults for production
    # instance_type_defaults = {
    #   web = "m6i.2xlarge" # 8 vCPUs, 32GB RAM x 2 instances
    #   boe = "m4.2xlarge" # 8 vCPUs, 32GB RAM x 2 instances
    #   bods = "r6i.2xlarge" # 8 vCPUs, 64GB RAM x 2 instance
    # }

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
        cloudwatch_metric_alarms = null # <= REMOVE THIS LATER
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
        cloudwatch_metric_alarms = null # <= REMOVE THIS LATER
      })

    }

    fsx_windows = {

      pd-bods-win-share = {
        preferred_availability_zone = "eu-west-2a"
        deployment_type             = "MULTI_AZ_1"
        security_groups             = ["bods"]
        skip_final_backup           = true
        storage_capacity            = 600
        throughput_capacity         = 8

        subnets = [
          {
            name               = "private"
            availability_zones = ["eu-west-2a", "eu-west-2b"]
          }
        ]

        self_managed_active_directory = {
          dns_ips = [
            module.ip_addresses.azure_fixngo_ip.PCMCW0011,
            module.ip_addresses.azure_fixngo_ip.PCMCW0012,
          ]
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

    # DO NOT FULLY DEPLOY YET AS WEB INSTANCES ARE NOT IN USE
    lbs = {
      public = merge(local.lbs.public, {
        instance_target_groups = {
          pd-onr-bods-http28080 = merge(local.lbs.public.instance_target_groups.http28080, {
            attachments = [
              { ec2_instance_name = "pd-onr-bods-1" },
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
                      "pd-bods.production.reporting.oasys.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })
        })
      })

      # No web instances built yet, not in use
      # private = {
      #   drop_invalid_header_fields       = false # https://me.sap.com/notes/0003348935
      #   enable_cross_zone_load_balancing = true
      #   enable_delete_protection         = false
      #   idle_timeout                     = 3600
      #   internal_lb                      = true
      #   load_balancer_type               = "application"
      #   security_groups                  = ["lb"]
      #   subnets                          = module.environment.subnets["private"].ids

      #   instance_target_groups = {
      #     pd-onr-web-1-a = {
      #       port     = 7777
      #       protocol = "HTTP"
      #       health_check = {
      #         enabled             = true
      #         healthy_threshold   = 3
      #         interval            = 30
      #         matcher             = "200-399"
      #         path                = "/"
      #         port                = 7777
      #         timeout             = 5
      #         unhealthy_threshold = 5
      #       }
      #       stickiness = {
      #         enabled = true
      #         type    = "lb_cookie"
      #       }
      #       attachments = [
      #         { ec2_instance_name = "pd-onr-web-1-a" },
      #       ]
      #     }
      #   }

      #   listeners = {
      #     http = {
      #       port     = 7777
      #       protocol = "HTTP"

      #       default_action = {
      #         type = "fixed-response"
      #         fixed_response = {
      #           content_type = "text/plain"
      #           message_body = "Not implemented"
      #           status_code  = "501"
      #         }
      #       }
      #       rules = {
      #         pd-onr-web-1-a = {
      #           priority = 4000

      #           actions = [{
      #             type              = "forward"
      #             target_group_name = "pd-onr-web-1-a"
      #           }]

      #           conditions = [{
      #             host_header = {
      #               values = [
      #                 "pd-onr-web-1-a.oasys-national-reporting.hmpps-production.modernisation-platform.service.justice.gov.uk",
      #               ]
      #             }
      #           }]
      #         }
      #       }
      #     }
      #     https = {
      #       certificate_names_or_arns = ["oasys_national_reporting_wildcard_cert"]
      #       port                      = 443
      #       protocol                  = "HTTPS"
      #       ssl_policy                = "ELBSecurityPolicy-2016-08"

      #       default_action = {
      #         type = "fixed-response"
      #         fixed_response = {
      #           content_type = "text/plain"
      #           message_body = "Not implemented"
      #           status_code  = "501"
      #         }
      #       }

      #       rules = {
      #         pd-onr-web-1-a = {
      #           priority = 4580

      #           actions = [{
      #             type              = "forward"
      #             target_group_name = "pd-onr-web-1-a"
      #           }]

      #           conditions = [{
      #             host_header = {
      #               values = [
      #                 "pd-onr-web-1-a.oasys-national-reporting.hmpps-production.modernisation-platform.service.justice.gov.uk",
      #               ]
      #             }
      #           }]
      #         }
      #       }
      #     }
      #   }
      # }
    } # end of lbs

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
      }
      "production.reporting.oasys.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "pd-bods", type = "A", lbs_map_key = "public" }
        ],
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
