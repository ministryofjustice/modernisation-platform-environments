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

    # WILL BE MOVING TO HMPPS-DOMAIN-SERVICES Account at a later date
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
          security_groups    = ["boe"]
        }]
        tags = {
          backup = "false"
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
        })
        cloudwatch_metric_alarms = null
        tags = merge(local.ec2_instances.bods.tags, {
          oasys-national-reporting-environment = "pp"
          domain-name                          = "azure.hmpp.root"
        })
      })

      # Pending sorting out cluster install of Bods in modernisation-platform-configuration-management repo
      # pp-onr-bods-2 = merge(local.ec2_instances.bods, {
      #   config = merge(local.ec2_instances.bods.config, {
      #     availability_zone = "eu-west-2b"
      #     user_data_raw = base64encode(templatefile(
      #       "./templates/user-data-onr-bods-pwsh.yaml.tftpl", {
      #         branch   = "main"
      #       }
      #     ))
      #     instance_profile_policies = concat(local.ec2_instances.bods.config.instance_profile_policies, [
      #       "Ec2SecretPolicy",
      #     ])
      #   })
      #   instance = merge(local.ec2_instances.bods.instance, {
      #     instance_type = "m6i.2xlarge"
      #   })
      #   cloudwatch_metric_alarms = null
      #   tags = merge(local.ec2_instances.bods.tags, {
      #     oasys-national-reporting-environment = "pp"
      #     domain-name = "azure.hmpp.root"
      #   })
      # cloudwatch_metric_alarms = {}
      # })
    }

    fsx_windows = {

      pp-bods-win-share = {
        deployment_type     = "SINGLE_AZ_1"
        security_groups     = ["bods"]
        skip_final_backup   = true
        storage_capacity    = 600
        throughput_capacity = 8

        subnets = [
          {
            name               = "private"
            availability_zones = ["eu-west-2a"]
          }
        ]

        self_managed_active_directory = {
          dns_ips = [
            module.ip_addresses.azure_fixngo_ip.PCMCW0011,
            module.ip_addresses.azure_fixngo_ip.PCMCW0012,
          ]
          domain_name          = "azure.hmpp.root"
          username             = "svc_admin"
          password_secret_name = "/sap/bods/pp/passwords"
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

    # DO NOT DEPLOY YET AS OTHER THINGS AREN'T READY
    lbs = {
      public = merge(local.lbs.public, {
        instance_target_groups = {
          pp-onr-bods-http28080 = merge(local.lbs.public.instance_target_groups.http28080, {
            attachments = [
              { ec2_instance_name = "pp-onr-bods-1" },
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
      #     pp-onr-web-1-a = {
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
      #         { ec2_instance_name = "pp-onr-web-1-a" },
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
      #         pp-onr-web-1-a = {
      #           priority = 4000

      #           actions = [{
      #             type              = "forward"
      #             target_group_name = "pp-onr-web-1-a"
      #           }]

      #           conditions = [{
      #             host_header = {
      #               values = [
      #                 "pp-onr-web-1-a.oasys-national-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk",
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
      #         pp-onr-web-1-a = {
      #           priority = 4580

      #           actions = [{
      #             type              = "forward"
      #             target_group_name = "pp-onr-web-1-a"
      #           }]

      #           conditions = [{
      #             host_header = {
      #               values = [
      #                 "pp-onr-web-1-a.oasys-national-reporting.hmpps-preproduction.modernisation-platform.service.justice.gov.uk",
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
      "preproduction.reporting.oasys.service.justice.gov.uk" = {
        lb_alias_records = [
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
