locals {

  baseline_presets_test = {
    options = {
      # sns_topics = {
      #   pagerduty_integrations = {
      #     dso_pagerduty               = "oasys_nonprod_alarms"
      #     dba_pagerduty               = "hmpps_shef_dba_non_prod" 
      #     dba_high_priority_pagerduty = "hmpps_shef_dba_non_prod"
      #   }
      # }
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
          security_groups    = ["boe"]
        }]
        tags = {
          backup = "false"
        }
      }
    }

    ec2_autoscaling_groups = {
      t2-test-web-asg = merge(local.defaults_web_ec2, {
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        availability_zone     = "eu-west-2a"
        config = merge(local.defaults_web_ec2.config, {
          instance_profile_policies = setunion(local.defaults_web_ec2.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "m4.large"
        })
        tags = merge(local.defaults_web_ec2.tags, {
          oasys-national-reporting-environment = "t2"
        })
      })

      # IMPORTANT: this is just for testing at the moment
      t2-rhel6-web-asg = merge(local.defaults_web_ec2, {
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "base_rhel_6_10_*"
          ami_owner         = "374269020027"
          availability_zone = "eu-west-2a"
          instance_profile_policies = setunion(local.defaults_web_ec2.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type                = "m4.large"
          metadata_options_http_tokens = "optional" # required as Rhel 6 cloud-init does not support IMDSv2
        })
        tags = merge(local.defaults_web_ec2.tags, {
          ami                                  = "base_rhel_6_10"
          oasys-national-reporting-environment = "t2"
        })
      })

      # TODO: this is just for testing, remove when not needed
      t2-test-boe-asg = merge(local.defaults_boe_ec2, {
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        config = merge(local.defaults_boe_ec2.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = setunion(local.defaults_boe_ec2.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
        })
        instance = merge(local.defaults_boe_ec2.instance, {
          instance_type = "m4.xlarge"
        })
        tags = merge(local.defaults_boe_ec2.tags, {
          oasys-national-reporting-environment = "t2"
        })
      })

      test-bods-asg = merge(local.defaults_bods_ec2, {
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        config = merge(local.defaults_bods_ec2.config, {
          availability_zone = "eu-west-2a"
        })
        instance = merge(local.defaults_bods_ec2.instance, {
          instance_type = "m4.xlarge"
        })
      })
    }

    ec2_instances = {
      t2-onr-bods-1-a = merge(local.defaults_bods_ec2, {
        config = merge(local.defaults_bods_ec2.config, {
          ami_name          = "hmpps_windows_server_2019_release_2024-05-02T00-00-37.552Z" # fixed to a specific version
          availability_zone = "eu-west-2a"
        })
        instance = merge(local.defaults_bods_ec2.instance, {
          instance_type = "m4.xlarge"
        })
        # volumes are a direct copy of BODS in NCR
        ebs_volumes = merge(local.defaults_bods_ec2.ebs_volumes, {
          "/dev/sda1" = { type = "gp3", size = 100 }
          "/dev/sdb"  = { type = "gp3", size = 100 }
          "/dev/sdc"  = { type = "gp3", size = 100 }
          "/dev/sds"  = { type = "gp3", size = 100 }
        })
      })

      t2-onr-boe-1-a = merge(local.defaults_boe_ec2, {
        config = merge(local.defaults_boe_ec2.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = setunion(local.defaults_boe_ec2.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
        })
        instance = merge(local.defaults_boe_ec2.instance, {
          instance_type = "m4.xlarge"
        })
        tags = merge(local.defaults_boe_ec2.tags, {
          oasys-national-reporting-environment = "t2"
        })
      })

      # NOTE: currently using a Rhel 6 instance for onr-web instances, not Rhel 7 & independent Tomcat install
      t2-onr-web-1-a = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "base_rhel_6_10_*"
          ami_owner         = "374269020027"
          availability_zone = "eu-west-2a"
          instance_profile_policies = setunion(local.defaults_web_ec2.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type                = "m4.large"
          metadata_options_http_tokens = "optional" # required as Rhel 6 cloud-init does not support IMDSv2
        })
        tags = merge(local.defaults_web_ec2.tags, {
          ami                                  = "base_rhel_6_10"
          oasys-national-reporting-environment = "t2"
        })
      })
      t2-onr-client-a = merge(local.jumpserver_ec2, {
        config = merge(local.jumpserver_ec2.config, {
          ami_name = "base_windows_server_2012_r2_release_2024-06-01T00-00-32.450Z"
        })
      })
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
              "arn:aws:secretsmanager:*:*:secret:/ec2/onr-boe/t2/*",
              "arn:aws:secretsmanager:*:*:secret:/ec2/onr-bods/t2/*",
              "arn:aws:secretsmanager:*:*:secret:/ec2/onr-web/t2/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*",
            ]
          }
        ]
      }
    }

    lbs = {
      private = {
        enable_cross_zone_load_balancing = true
        enable_delete_protection         = false
        idle_timeout                     = 3600
        internal_lb                      = true
        load_balancer_type               = "application"
        security_groups                  = ["lb"]
        subnets                          = module.environment.subnets["private"].ids

        instance_target_groups = {
          t2-onr-web-1-a = {
            port     = 7777
            protocol = "HTTP"
            health_check = {
              enabled             = true
              healthy_threshold   = 3
              interval            = 30
              matcher             = "200-399"
              path                = "/"
              port                = 7777
              timeout             = 5
              unhealthy_threshold = 5
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
            attachments = [
              { ec2_instance_name = "t2-onr-web-1-a" },
            ]
          }
        }

        listeners = {
          http = {
            port     = 7777
            protocol = "HTTP"

            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "Not implemented"
                status_code  = "501"
              }
            }
            rules = {
              t2-onr-web-1-a = {
                priority = 4000

                actions = [{
                  type              = "forward"
                  target_group_name = "t2-onr-web-1-a"
                }]

                conditions = [{
                  host_header = {
                    values = [
                      "t2-onr-web-1-a.oasys-national-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          }
          https = {
            certificate_names_or_arns = ["oasys_national_reporting_wildcard_cert"]
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-2016-08"

            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "Not implemented"
                status_code  = "501"
              }
            }

            rules = {
              t2-onr-web-1-a = {
                priority = 4580

                actions = [{
                  type              = "forward"
                  target_group_name = "t2-onr-web-1-a"
                }]

                conditions = [{
                  host_header = {
                    values = [
                      "t2-onr-web-1-a.oasys-national-reporting.hmpps-test.modernisation-platform.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          }
        }
      }
    }

    route53_zones = {
      "test.reporting.oasys.service.justice.gov.uk" = {}
    }

    secretsmanager_secrets = {
      "/ec2/onr-bods/t2"         = local.bods_secretsmanager_secrets
      "/ec2/onr-boe/t2"          = local.boe_secretsmanager_secrets
      "/ec2/onr-web/t2"          = local.web_secretsmanager_secrets
      "/oracle/database/T2BOSYS" = local.database_secretsmanager_secrets
      "/oracle/database/T2BOAUD" = local.database_secretsmanager_secrets
    }
  }
}
