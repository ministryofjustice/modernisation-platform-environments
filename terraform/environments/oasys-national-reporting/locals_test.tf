locals {

  baseline_presets_test = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "oasys-national-reporting-test"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_test = {

    acm_certificates = {
      oasys_national_reporting_wildcard_cert = {
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "modernisation-platform.service.justice.gov.uk"
        external_validation_records_created = true
        subject_alternate_names = [
          "*.oasys-national-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk",
          "test.reporting.oasys.service.justice.gov.uk",
          "*.test.reporting.oasys.service.justice.gov.uk",
        ] # NOTE: there is no azure cert equivalent for T2
        tags = {
          description = "Wildcard certificate for the test environment"
        }
      }
    }

    efs = {
      t2-onr-sap-share = {
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
          security_groups    = ["boe", "bip-app"]
        }]
        tags = {
          backup      = "false"
          backup-plan = "daily-and-weekly"
        }
      }
    }

    ec2_autoscaling_groups = {
      t2-onr-cms = merge(local.ec2_autoscaling_groups.bip_cms, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.bip_cms.autoscaling_group, {
          desired_capacity = 0
          max_size         = 2
        })
        config = merge(local.ec2_autoscaling_groups.bip_cms.config, {
          instance_profile_policies = concat(local.ec2_autoscaling_groups.bip_cms.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.bip_cms.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.bip_cms.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.bip_cms.tags, {
          oasys-national-reporting-environment = "t2"
        })
      })

      t2-onr-web = merge(local.ec2_autoscaling_groups.bip_web, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.bip_web.autoscaling_group, {
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.bip_web.config, {
          instance_profile_policies = concat(local.ec2_autoscaling_groups.bip_web.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.bip_web.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.bip_web.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.bip_web.tags, {
          oasys-national-reporting-environment = "t2"
        })
      })

      t2-test-web-asg = merge(local.ec2_autoscaling_groups.boe_web, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.boe_web.autoscaling_group, {
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.boe_web.config, {
          instance_profile_policies = concat(local.ec2_autoscaling_groups.boe_web.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
        })
        instance = merge(local.ec2_autoscaling_groups.boe_web.instance, {
          instance_type = "m4.large"
        })
        tags = merge(local.ec2_autoscaling_groups.boe_web.tags, {
          oasys-national-reporting-environment = "t2"
        })
        cloudwatch_metric_alarms = null
      })

      # TODO: this is just for testing, remove when not needed
      t2-rhel6-web-asg = merge(local.ec2_autoscaling_groups.boe_web, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.boe_web.autoscaling_group, {
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.boe_web.config, {
          ami_name = "base_rhel_6_10_*"
          instance_profile_policies = setunion(local.ec2_autoscaling_groups.boe_web.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
        })
        instance = merge(local.ec2_autoscaling_groups.boe_web.instance, {
          instance_type                = "m4.large"
          metadata_options_http_tokens = "optional" # required as Rhel 6 cloud-init does not support IMDSv2
        })
        tags = merge(local.ec2_autoscaling_groups.boe_web.tags, {
          ami                                  = "base_rhel_6_10"
          oasys-national-reporting-environment = "t2"
        })
        cloudwatch_metric_alarms = null
      })

      # TODO: this is just for testing, remove when not needed
      t2-test-boe-asg = merge(local.ec2_autoscaling_groups.boe_app, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.boe_app.autoscaling_group, {
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.boe_app.config, {
          instance_profile_policies = concat(local.ec2_autoscaling_groups.boe_app.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
        })
        instance = merge(local.ec2_autoscaling_groups.boe_app.instance, {
          instance_type = "m4.xlarge"
        })
        tags = merge(local.ec2_autoscaling_groups.boe_app.tags, {
          oasys-national-reporting-environment = "t2"
        })
        cloudwatch_metric_alarms = null
      })

      # TODO: this is just for testing, remove when not needed
      t2-tst-bods-asg = merge(local.ec2_autoscaling_groups.bods, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.bods.autoscaling_group, {
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.bods.config, {
          instance_profile_policies = concat(local.ec2_autoscaling_groups.bods.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
          user_data_raw = base64encode(templatefile(
            "./templates/user-data-onr-bods-pwsh.yaml.tftpl", {
              branch = "main"
          }))
        })
        instance = merge(local.ec2_autoscaling_groups.bods.instance, {
          instance_type = "m4.xlarge"
        })
        tags = merge(local.ec2_autoscaling_groups.bods.tags, {
          oasys-national-reporting-environment = "t2"
          domain-name                          = "azure.noms.root"
        })
        cloudwatch_metric_alarms = null
      })
    }

    ec2_instances = {

      t2-onr-bods-1 = merge(local.ec2_instances.bods, {
        config = merge(local.ec2_instances.bods.config, {
          ami_name          = "hmpps_windows_server_2019_release_2024-12-02T00-00-37.662Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bods.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bods.instance, {
          instance_type = "m4.xlarge"
        })
        cloudwatch_metric_alarms = merge(
          module.baseline_presets.cloudwatch_metric_alarms.ec2,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows,
          local.cloudwatch_metric_alarms.windows,
          local.cloudwatch_metric_alarms.bods_primary,
        )
        tags = merge(local.ec2_instances.bods.tags, {
          oasys-national-reporting-environment = "t2"
          domain-name                          = "azure.noms.root"
        })
      })

      t2-onr-bods-2 = merge(local.ec2_instances.bods, {
        config = merge(local.ec2_instances.bods.config, {
          ami_name          = "hmpps_windows_server_2019_release_2024-12-02T00-00-37.662Z"
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.ec2_instances.bods.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bods.instance, {
          instance_type = "m4.xlarge"
        })
        cloudwatch_metric_alarms = merge(
          module.baseline_presets.cloudwatch_metric_alarms.ec2,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows,
          local.cloudwatch_metric_alarms.windows,
          local.cloudwatch_metric_alarms.bods_secondary,
        )
        tags = merge(local.ec2_instances.bods.tags, {
          oasys-national-reporting-environment = "t2"
          domain-name                          = "azure.noms.root"
        })
      })

      t2-onr-cms-1 = merge(local.ec2_instances.bip_cms, {
        config = merge(local.ec2_instances.bip_cms.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_cms.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip_cms.instance, {
          instance_type = "m6i.xlarge"
        })
        user_data_cloud_init = merge(local.ec2_instances.bip_cms.user_data_cloud_init, {
          args = merge(local.ec2_instances.bip_cms.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.bip_cms.tags, {
          instance-scheduling                  = "skip-scheduling"
          oasys-national-reporting-environment = "t2"
        })
      })

      t2-onr-web-1 = merge(local.ec2_instances.bip_web, {
        config = merge(local.ec2_instances.bip_web.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_web.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip_web.instance, {
          instance_type = "r6i.large"
        })
        user_data_cloud_init = merge(local.ec2_instances.bip_web.user_data_cloud_init, {
          args = merge(local.ec2_instances.bip_web.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.bip_web.tags, {
          instance-scheduling                  = "skip-scheduling"
          oasys-national-reporting-environment = "t2"
        })
      })

      # NOTE: These are all BOE 3.1 instances and are not currently needed
      # t2-onr-boe-1-a = merge(local.ec2_instances.boe_app, {
      #   config = merge(local.ec2_instances.boe_app.config, {
      #     availability_zone = "eu-west-2a"
      #     instance_profile_policies = setunion(local.ec2_instances.boe_app.config.instance_profile_policies, [
      #       "Ec2SecretPolicy",
      #     ])
      #   })
      #   instance = merge(local.ec2_instances.boe_app.instance, {
      #     instance_type = "m4.xlarge"
      #   })
      #   tags = merge(local.ec2_instances.boe_app.tags, {
      #     oasys-national-reporting-environment = "t2"
      #   })
      # })

      # # NOTE: currently using a Rhel 6 instance for onr-web instances, not Rhel 7 & independent Tomcat install
      # t2-onr-web-1-a = merge(local.ec2_instances.boe_web, {
      #   config = merge(local.ec2_instances.boe_web.config, {
      #     ami_name          = "base_rhel_6_10_*"
      #     availability_zone = "eu-west-2a"
      #     instance_profile_policies = setunion(local.ec2_instances.boe_web.config.instance_profile_policies, [
      #       "Ec2SecretPolicy",
      #     ])
      #   })
      #   instance = merge(local.ec2_instances.boe_web.instance, {
      #     instance_type                = "m4.large"
      #     metadata_options_http_tokens = "optional" # required as Rhel 6 cloud-init does not support IMDSv2
      #   })
      #   tags = merge(local.ec2_instances.boe_web.tags, {
      #     ami                                  = "base_rhel_6_10"
      #     oasys-national-reporting-environment = "t2"
      #   })
      # })
      # t2-onr-client-a = merge(local.ec2_instances.jumpserver, {
      #   config = merge(local.ec2_instances.jumpserver.config, {
      #     ami_name          = "base_windows_server_2012_r2_release_2024-06-01T00-00-32.450Z"
      #     availability_zone = "eu-west-2a"
      #   })
      #   tags = merge(local.ec2_instances.jumpserver.tags, {
      #     domain-name = "azure.noms.root"
      #   })
      # })
    }

    fsx_windows = {
      t2-bods-win-share = {
        aliases                         = ["t2-onr-fs.azure.noms.root"]
        automatic_backup_retention_days = 0
        deployment_type                 = "SINGLE_AZ_1"
        security_groups                 = ["bods"]
        skip_final_backup               = true
        storage_capacity                = 128
        throughput_capacity             = 8

        subnets = [
          {
            name               = "private"
            availability_zones = ["eu-west-2a"]
          }
        ]

        self_managed_active_directory = {
          dns_ips = [
            module.ip_addresses.mp_ip.ad-azure-dc-a,
            module.ip_addresses.mp_ip.ad-azure-dc-b,
          ]
          domain_name          = "azure.noms.root"
          username             = "svc_join_domain"
          password_secret_name = "/sap/bods/t2/passwords"
        }
        tags = {
          backup      = false
          backup-plan = "daily-and-weekly"
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
              "arn:aws:secretsmanager:*:*:secret:/sap/bods/t2/*",
              "arn:aws:secretsmanager:*:*:secret:/sap/bip/t2/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*",
            ]
          }
        ]
      }
    }

    lbs = {
      public = merge(local.lbs.public, {
        instance_target_groups = {
          t2-onr-bods-http28080 = merge(local.lbs.public.instance_target_groups.http28080, {
            attachments = [
              { ec2_instance_name = "t2-onr-bods-1" },
              # { ec2_instance_name = "t2-onr-bods-2" },
            ]
          })
          t2-onr-web-http-7777 = merge(local.lbs.public.instance_target_groups.http-7777, {
            attachments = [
              { ec2_instance_name = "t2-onr-web-1" },
            ]
          })
        }
        listeners = merge(local.lbs.public.listeners, {
          https = merge(local.lbs.public.listeners.https, {
            alarm_target_group_names = []
            rules = {
              t2-onr-bods-http28080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-onr-bods-http28080"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t2-bods.test.reporting.oasys.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t2-onr-web-http-7777 = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-onr-web-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t2.test.reporting.oasys.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })
        })
      })

      #   private = {
      #     drop_invalid_header_fields       = false # https://me.sap.com/notes/0003348935
      #     enable_cross_zone_load_balancing = true
      #     enable_delete_protection         = false
      #     idle_timeout                     = 3600
      #     internal_lb                      = true
      #     load_balancer_type               = "application"
      #     security_groups                  = ["lb"]
      #     subnets                          = module.environment.subnets["private"].ids

      #     instance_target_groups = {
      #       t2-onr-web-1-a = {
      #         port     = 7777
      #         protocol = "HTTP"
      #         health_check = {
      #           enabled             = true
      #           healthy_threshold   = 3
      #           interval            = 30
      #           matcher             = "200-399"
      #           path                = "/"
      #           port                = 7777
      #           timeout             = 5
      #           unhealthy_threshold = 5
      #         }
      #         stickiness = {
      #           enabled = true
      #           type    = "lb_cookie"
      #         }
      #         attachments = [
      #           { ec2_instance_name = "t2-onr-web-1-a" },
      #         ]
      #       }
      #     }

      #     listeners = {
      #       http = {
      #         port     = 7777
      #         protocol = "HTTP"

      #         default_action = {
      #           type = "fixed-response"
      #           fixed_response = {
      #             content_type = "text/plain"
      #             message_body = "Not implemented"
      #             status_code  = "501"
      #           }
      #         }
      #         rules = {
      #           t2-onr-web-1-a = {
      #             priority = 4000

      #             actions = [{
      #               type              = "forward"
      #               target_group_name = "t2-onr-web-1-a"
      #             }]

      #             conditions = [{
      #               host_header = {
      #                 values = [
      #                   "t2-onr-web-1-a.oasys-national-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk",
      #                 ]
      #               }
      #             }]
      #           }
      #         }
      #       }
      #       https = {
      #         certificate_names_or_arns = ["oasys_national_reporting_wildcard_cert"]
      #         port                      = 443
      #         protocol                  = "HTTPS"
      #         ssl_policy                = "ELBSecurityPolicy-2016-08"

      #         default_action = {
      #           type = "fixed-response"
      #           fixed_response = {
      #             content_type = "text/plain"
      #             message_body = "Not implemented"
      #             status_code  = "501"
      #           }
      #         }

      #         rules = {
      #           t2-onr-web-1-a = {
      #             priority = 4580

      #             actions = [{
      #               type              = "forward"
      #               target_group_name = "t2-onr-web-1-a"
      #             }]

      #             conditions = [{
      #               host_header = {
      #                 values = [
      #                   "t2-onr-web-1-a.oasys-national-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk",
      #                 ]
      #               }
      #             }]
      #           }
      #         }
      #       }
      #     }
      #   }
    }

    route53_zones = {
      "test.reporting.oasys.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "t2", type = "A", lbs_map_key = "public" },
          { name = "t2-bods", type = "A", lbs_map_key = "public" },
        ],
      }
    }

    secretsmanager_secrets = {
      "/sap/bods/t2"             = local.secretsmanager_secrets.bods
      "/sap/bip/t2"              = local.secretsmanager_secrets.bip
      "/oracle/database/T2BOSYS" = local.secretsmanager_secrets.db
      "/oracle/database/T2BOAUD" = local.secretsmanager_secrets.db
    }
  }
}
