# environment specific settings
locals {

  # cloudwatch monitoring config
  test_cloudwatch_monitoring_options = {
    enable_hmpps-oem_monitoring = true
    enable_cloudwatch_dashboard = true
  }

  test_baseline_presets_options = {
    enable_observability_platform_monitoring = true
    sns_topics = {
      pagerduty_integrations = {
        dso_pagerduty               = "oasys_nonprod_alarms"
        dba_pagerduty               = "hmpps_shef_dba_non_prod"
        dba_high_priority_pagerduty = "hmpps_shef_dba_non_prod"
      }
    }
  }

  # baseline config
  test_config = {

    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    baseline_s3_buckets     = {}
    baseline_ssm_parameters = {}

    baseline_secretsmanager_secrets = {
      "/oracle/database/T1OASYS"  = local.secretsmanager_secrets_oasys_db
      "/oracle/database/T1OASREP" = local.secretsmanager_secrets_db
      "/oracle/database/T1AZBIPI" = local.secretsmanager_secrets_bip_db
      "/oracle/database/T1BIPINF" = local.secretsmanager_secrets_bip_db
      "/oracle/database/T1MISTRN" = local.secretsmanager_secrets_db
      "/oracle/database/T1ONRSYS" = local.secretsmanager_secrets_db
      "/oracle/database/T1ONRAUD" = local.secretsmanager_secrets_db
      "/oracle/database/T1ONRBDS" = local.secretsmanager_secrets_db

      "/oracle/database/T2OASYS"  = local.secretsmanager_secrets_oasys_db
      "/oracle/database/T2OASREP" = local.secretsmanager_secrets_db
      "/oracle/database/T2AZBIPI" = local.secretsmanager_secrets_bip_db
      "/oracle/database/T2BIPINF" = local.secretsmanager_secrets_bip_db
      "/oracle/database/T2MISTRN" = local.secretsmanager_secrets_db
      "/oracle/database/T2ONRSYS" = local.secretsmanager_secrets_db
      "/oracle/database/T2ONRAUD" = local.secretsmanager_secrets_db
      "/oracle/database/T2ONRBDS" = local.secretsmanager_secrets_db

      "/oracle/bip/t1" = local.secretsmanager_secrets_bip
      "/oracle/bip/t2" = local.secretsmanager_secrets_bip
    }

    baseline_iam_policies = {
      Ec2T2WebPolicy = {
        description = "Permissions required for T2 Web EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T2OASYS/apex-passwords*",
            ]
          }
        ]
      }
      Ec2T1WebPolicy = {
        description = "Permissions required for T1 Web EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T1OASYS/apex-passwords*",
            ]
          }
        ]
      }
      Ec2T2BipPolicy = {
        description = "Permissions required for T2 Bip EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/bip/t2/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*T2/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T2*/bip-*",
            ]
          }
        ]
      }
      Ec2T1BipPolicy = {
        description = "Permissions required for T1 Bip EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/bip/t1/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*T1/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T1*/bip-*",
            ]
          }
        ]
      }
      Ec2T1DatabasePolicy = {
        description = "Permissions required for T1 Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "ssm:GetParameter",
            ]
            resources = [
              "arn:aws:ssm:*:*:parameter/azure/*",
            ]
          },
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*T1/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T1*/*",
            ]
          }
        ]
      }
      Ec2T2DatabasePolicy = {
        description = "Permissions required for T2 Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "ssm:GetParameter",
            ]
            resources = [
              "arn:aws:ssm:*:*:parameter/azure/*",
            ]
          },
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*T2/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T2*/*",
            ]
          }
        ]
      }
    }

    baseline_ec2_instances = {
      ##
      ## T2
      ##
      "t2-${local.application_name}-db-a" = merge(local.database_a, {
        instance = merge(local.database_a.instance, {
          instance_type = "r6i.xlarge"
        })
        config = merge(local.database_a.config, {
          instance_profile_policies = concat(local.database_a.config.instance_profile_policies, [
            "Ec2T2DatabasePolicy",
          ])
        })
        ebs_volumes = {
          "/dev/sdb" = { # /u01
            size  = 100
            label = "app"
            type  = "gp3"
          }
          "/dev/sdc" = { # /u02
            size  = 500
            label = "app"
            type  = "gp3"
          }
          "/dev/sde" = { # DATA01
            label = "data"
            size  = 500
            type  = "gp3"
          }
          "/dev/sdf" = { # DATA02
            label = "data"
            size  = 50
            type  = "gp3"
          }
          "/dev/sdj" = { # FLASH01
            label = "flash"
            type  = "gp3"
            size  = 50
          }
          "/dev/sds" = {
            label = "swap"
            type  = "gp3"
            size  = 2
          }
        }
        tags = merge(local.database_a.tags, {
          description                             = "t2 ${local.application_name} database"
          "${local.application_name}-environment" = "t2"
          bip-db-name                             = "T2BIPINF"
          instance-scheduling                     = "skip-scheduling"
          oracle-sids                             = "T2BIPINF T2MISTRN T2OASREP T2OASYS T2ONRAUD T2ONRBDS T2ONRSYS"
        })
      })

      "t2-${local.application_name}-bip-a" = merge(local.bip_a, {
        autoscaling_group = merge(local.bip_a.autoscaling_group, {
          desired_capacity = 1
        })
        autoscaling_schedules = {}
        config = merge(local.bip_a.config, {
          instance_profile_policies = concat(local.bip_a.config.instance_profile_policies, [
            "Ec2T2BipPolicy",
          ])
        })
        # user_data_cloud_init  = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags, {
        #   args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags.args, {
        #     branch = "add-oasys-bip-role"
        #   })
        # })
        tags = merge(local.bip_a.tags, {
          oasys-environment = "t2"
          bip-db-name       = "T2BIPINF"
          bip-db-hostname   = "t2-oasys-db-a"
          oasys-db-name     = "T2OASYS"
          oasys-db-hostname = "t2-oasys-db-a"
        })
      })

      ##
      ## T1
      ##
      "t1-${local.application_name}-db-a" = merge(local.database_a, {
        config = merge(local.database_a.config, {
          instance_profile_policies = concat(local.database_a.config.instance_profile_policies, [
            "Ec2T1DatabasePolicy",
          ])
        })
        instance = merge(local.database_a.instance, {
          instance_type = "r6i.xlarge"
        })
        ebs_volumes = {
          "/dev/sdb" = { # /u01
            size  = 100
            label = "app"
            type  = "gp3"
          }
          "/dev/sdc" = { # /u02
            size  = 500
            label = "app"
            type  = "gp3"
          }
          "/dev/sde" = { # DATA01
            label = "data"
            size  = 500
            type  = "gp3"
          }
          "/dev/sdf" = { # DATA02
            label = "data"
            size  = 50
            type  = "gp3"
          }
          "/dev/sdj" = { # FLASH01
            label = "flash"
            type  = "gp3"
            size  = 50
          }
          "/dev/sds" = {
            label = "swap"
            type  = "gp3"
            size  = 2
          }
        }
        tags = merge(local.database_a.tags, {
          description                             = "t1 ${local.application_name} database"
          "${local.application_name}-environment" = "t1"
          bip-db-name                             = "T1BIPINF"
          instance-scheduling                     = "skip-scheduling"
          oracle-sids                             = "T1BIPINF T1MISTRN T1OASREP T1OASYS T1ONRAUD T1ONRBDS T1ONRSYS"
        })
      })

      "t1-${local.application_name}-bip-a" = merge(local.bip_a, {
        autoscaling_group = merge(local.bip_b.autoscaling_group, {
          desired_capacity = 1
        })
        autoscaling_schedules = {}
        config = merge(local.bip_a.config, {
          instance_profile_policies = concat(local.bip_a.config.instance_profile_policies, [
            "Ec2T1BipPolicy",
          ])
        })
        # user_data_cloud_init  = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags, {
        #   args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags.args, {
        #     branch = "add-oasys-bip-role"
        #   })
        # })
        tags = merge(local.bip_b.tags, {
          oasys-environment = "t1"
          bip-db-name       = "T1BIPINF"
          bip-db-hostname   = "t1-oasys-db-a"
          oasys-db-name     = "T1OASYS"
          oasys-db-hostname = "t1-oasys-db-a"
        })
      })

      # "t1-${local.application_name}-bip-b" = merge(local.bip_b, {
      #   autoscaling_group = merge(local.bip_b.autoscaling_group, {
      #     desired_capacity = 1
      #   })
      #   autoscaling_schedules = {}
      #   config = merge(local.bip_b.config, {
      #     instance_profile_policies = concat(local.bip_b.config.instance_profile_policies, [
      #       "Ec2T1BipPolicy",
      #     ])
      #     # ami_name                  = "base_rhel_7_9*"
      #   })
      #   user_data_cloud_init  = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags, {
      #     args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags.args, {
      #       branch = "oasys/bip-build-improvement2"
      #     })
      #   })
      #   tags = merge(local.bip_b.tags, {
      #     oasys-environment   = "t1"
      #     bip-db-name         = "T1BIPINF"
      #     bip-db-hostname     = "t1-oasys-db-a"
      #     oasys-db-name       = "T1OASYS"
      #     oasys-db-hostname   = "t1-oasys-db-a"
      #   })
      # })
    }

    baseline_ec2_autoscaling_groups = {
      ##
      ## T2
      ##
      "t2-${local.application_name}-web-a" = merge(local.webserver_a, {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                  = "oasys_webserver_release_*"
          ssm_parameters_prefix     = "ec2-web-t2/"
          iam_resource_names_prefix = "ec2-web-t2"
          instance_profile_policies = concat(local.webserver_a.config.instance_profile_policies, [
            "Ec2T2WebPolicy",
          ])
        })
        tags = merge(local.webserver_a.tags, {
          description                             = "t2 ${local.application_name} web"
          "${local.application_name}-environment" = "t2"
          oracle-db-hostname                      = "db.t2.oasys.hmpps-test.modernisation-platform.internal"
          oracle-db-sid                           = "T2OASYS" # for each env using azure DB will need to be OASPROD
        })
      })
      # "t2-${local.application_name}-web-b" = merge(local.webserver_b, {
      #   config = merge(module.baseline_presets.ec2_instance.config.default, {
      #     ami_name                  = "oasys_webserver_release_*"
      #     ssm_parameters_prefix     = "ec2-web-t2/"
      #     iam_resource_names_prefix = "ec2-web-t2"
      #     instance_profile_policies = concat(local.webserver_b.config.instance_profile_policies, [
      #       "Ec2T2WebPolicy",
      #     ])
      #   })
      #   user_data_cloud_init  = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags, {
      #     args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags.args, {
      #       branch = "ords_parameter_file_update"
      #     })
      #   })
      #   #autoscaling_group  = module.baseline_presets.ec2_autoscaling_group.cold_standby
      #   tags = merge(local.webserver_a.tags, {
      #     description                             = "t2 ${local.application_name} web"
      #     "${local.application_name}-environment" = "t2"
      #     oracle-db-hostname                      = "db.t2.oasys.hmpps-test.modernisation-platform.internal"
      #     oracle-db-sid                           = "T2OASYS" # for each env using azure DB will need to be OASPROD
      #   })
      # })

      ##
      ## T1
      ##
      "t1-${local.application_name}-web-a" = merge(local.webserver_a, {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                  = "oasys_webserver_release_*"
          ssm_parameters_prefix     = "ec2-web-t1/"
          iam_resource_names_prefix = "ec2-web-t1"
          instance_profile_policies = concat(local.webserver_a.config.instance_profile_policies, [
            "Ec2T1WebPolicy",
          ])
        })
        tags = merge(local.webserver_a.tags, {
          description                             = "t1 ${local.application_name} web"
          "${local.application_name}-environment" = "t1"
          oracle-db-hostname                      = "db.t1.oasys.hmpps-test.modernisation-platform.internal"
          oracle-db-sid                           = "T1OASYS" # for each env using azure DB will need to be OASPROD
        })
      })

      # "t1-${local.application_name}-web-b" = merge(local.webserver_b, {
      #   config = merge(module.baseline_presets.ec2_instance.config.default, {
      #     ami_name                  = "oasys_webserver_release_*"
      #     ssm_parameters_prefix     = "ec2-web-t1/"
      #     iam_resource_names_prefix = "ec2-web-t1"
      #     instance_profile_policies = concat(local.webserver_b.config.instance_profile_policies, [
      #       "Ec2T1WebPolicy",
      #     ])
      #   })
      #   user_data_cloud_init  = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags, {
      #     args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags.args, {
      #       branch = "ords_parameter_file_update"
      #     })
      #   })
      #   tags = merge(local.webserver_b.tags, {
      #     description                             = "t1 ${local.application_name} web"
      #     "${local.application_name}-environment" = "t1"
      #     oracle-db-hostname                      = "db.t1.oasys.hmpps-test.modernisation-platform.internal"
      #     oracle-db-sid                           = "T1OASYS" # for each env using azure DB will need to be OASPROD
      #   })
      # })

      ##
      ## test
      ##
      # "test-${local.application_name}-bip-a" = merge(local.bip_a, {
      #   autoscaling_schedules = {}
      #   tags = merge(local.bip_a.tags, {
      #     oracle-db-hostname-a = "t2-oasys-db-a"
      #     oracle-db-hostname-b = "t2-oasys-db-b"
      #     oracle-db-name       = "T2BIPINF"
      #   })
      # })
    }


    # If your DNS records are in Fix 'n' Go, setup will be a 2 step process, see the acm_certificate module readme
    # if making changes, comment out the listeners that use the cert, edit the cert, recreate the listeners
    baseline_acm_certificates = {
      "t2_${local.application_name}_cert" = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = "t2.oasys.service.justice.gov.uk"
        subject_alternate_names = [
          "*.oasys.service.justice.gov.uk",
          "*.hmpp-azdt.justice.gov.uk",
          "ords.t2.oasys.service.justice.gov.uk",
          "ords.t1.oasys.service.justice.gov.uk",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "cert for t2 ${local.application_name} ${local.environment} domains"
        }
      }
    }

    # options for LBs https://docs.google.com/presentation/d/1RpXpfNY_hw7FjoMw0sdMAdQOF7kZqLUY6qVVtLNavWI/edit?usp=sharing
    baseline_lbs = {
      # public = { # just left here to see how to set up an NLB
      #   load_balancer_type       = "network"
      #   internal_lb              = false
      #   access_logs              = false # NLB don't have access logs unless they have a tls listener
      #   # force_destroy_bucket     = true
      #   # s3_versioning            = false
      #   enable_delete_protection = false
      #   existing_target_groups = {
      #     "private-lb-https-443" = {
      #       arn = length(aws_lb_target_group.private-lb-https-443) > 0 ? aws_lb_target_group.private-lb-https-443[0].arn : ""
      #     }
      #   }
      #   idle_timeout    = 3600 # 60 is default
      #   security_groups = [] # no security groups for network load balancers
      #   subnets         = module.environment.subnets["public"].ids
      #   tags            = local.tags
      #   listeners = {
      #     https = {
      #       port     = 443
      #       protocol = "TCP"
      #       default_action = {
      #         type              = "forward"
      #         target_group_name = "private-lb-https-443"
      #       }
      #     }
      #   }
      # }

      public = {
        internal_lb              = false
        access_logs              = false
        force_destroy_bucket     = true
        enable_delete_protection = false
        existing_target_groups = {
        }
        idle_timeout    = 3600 # 60 is default
        security_groups = ["public_lb"]
        subnets         = module.environment.subnets["public"].ids
        tags            = local.tags

        listeners = {
          https = {
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-2016-08"
            certificate_names_or_arns = ["t2_${local.application_name}_cert"]
            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "T2 - use t2.oasys.service.justice.gov.uk, T1 - use t1.oasys.service.justice.gov.uk"
                status_code  = "200"
              }
            }
            # default_action = {
            #   type              = "forward"
            #   target_group_name = "t2-${local.application_name}-web-a-pb-http-8080"
            # }
            rules = {
              t2-web-http-8080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-${local.application_name}-web-a-pb-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "t2.oasys.service.justice.gov.uk",
                        "t2-a.oasys.service.justice.gov.uk",
                        "ords.t2.oasys.service.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
              # t2-web-b-http-8080 = {
              #   priority = 200
              #   actions = [{
              #     type              = "forward"
              #     target_group_name = "t2-${local.application_name}-web-b-pb-http-8080"
              #   }]
              #   conditions = [
              #     {
              #       host_header = {
              #         values = [
              #           "t2-b.oasys.service.justice.gov.uk",
              #         ]
              #       }
              #     }
              #   ]
              # }
              t1-web-http-8080 = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-${local.application_name}-web-a-pb-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "t1.oasys.service.justice.gov.uk",
                        "t1-a.oasys.service.justice.gov.uk",
                        "ords.t1.oasys.service.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
            }
          }
        }
      }
      private = {
        internal_lb = true
        access_logs = false
        # s3_versioning            = false
        force_destroy_bucket     = true
        enable_delete_protection = false
        existing_target_groups   = {}
        idle_timeout             = 3600 # 60 is default
        security_groups          = ["private_lb"]
        subnets                  = module.environment.subnets["private"].ids
        tags                     = local.tags
        listeners = {
          https = {
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-2016-08"
            certificate_names_or_arns = ["t2_${local.application_name}_cert"]
            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "T2 - use t2-int.oasys.service.justice.gov.uk, T1 - use t1-int.oasys.service.justice.gov.uk"
                status_code  = "200"
              }
            }
            # default_action = {
            #   type              = "forward"
            #   target_group_name = "t2-${local.application_name}-web-a-pv-http-8080"
            # }
            rules = {
              t2-web-http-8080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-${local.application_name}-web-a-pv-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "t2-int.oasys.service.justice.gov.uk",
                        "t2-a-int.oasys.service.justice.gov.uk",
                        "t2-oasys.hmpp-azdt.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
              # t2-web-b-http-8080 = {
              #   priority = 200
              #   actions = [{
              #     type              = "forward"
              #     target_group_name = "t2-${local.application_name}-web-b-pv-http-8080"
              #   }]
              #   conditions = [
              #     {
              #       host_header = {
              #         values = [
              #           "t2-b-int.oasys.service.justice.gov.uk",
              #         ]
              #       }
              #     }
              #   ]
              # }
              t1-web-http-8080 = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-${local.application_name}-web-a-pv-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "t1-int.oasys.service.justice.gov.uk",
                        "t1-a-int.oasys.service.justice.gov.uk",
                        "t1-oasys.hmpp-azdt.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
            }
          }
        }
      }
    }


    # The following zones can be found on azure:
    # az.justice.gov.uk
    # oasys.service.justice.gov.uk
    baseline_route53_zones = {
      #
      # public
      #
      # "${local.application_name}.service.justice.gov.uk" = {
      #   lb_alias_records = [
      # { name = "t2",    type = "A", lbs_map_key = "public" }, #    t2.oasys.service.justice.gov.uk 
      # { name = "db.t2", type = "A", lbs_map_key = "public" }, # db.t2.oasys.service.justice.gov.uk
      #   ]
      # }
      # "t1.${local.application_name}.service.justice.gov.uk" = {
      #   lb_alias_records = [
      #     { name = "web", type = "A", lbs_map_key = "public" }, # web.t1.oasys.service.justice.gov.uk # need to add an ns record to oasys.service.justice.gov.uk -> t1, 
      #     { name = "db", type = "A", lbs_map_key = "public" },
      #   ]
      # }
      (module.environment.domains.public.business_unit_environment) = { # hmpps-test.modernisation-platform.service.justice.gov.uk
        records = [
          { name = "db.t2.${local.application_name}", type = "CNAME", ttl = "3600", records = ["t2-oasys-db-a.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "db.t1.${local.application_name}", type = "CNAME", ttl = "3600", records = ["t1-oasys-db-a.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
        ]
        # lb_alias_records = [
        #   { name = "t2.${local.application_name}", type = "A", lbs_map_key = "public" },     # t2.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk
        #   { name = "web.t2.${local.application_name}", type = "A", lbs_map_key = "public" }, # web.t2.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk
        #   { name = "db.t2.${local.application_name}", type = "A", lbs_map_key = "public" },
        #   { name = "db.t1.${local.application_name}", type = "A", lbs_map_key = "public" },
        # ]
      }
      #
      # internal/private
      #
      (module.environment.domains.internal.business_unit_environment) = { # hmpps-test.modernisation-platform.internal
        vpc = {                                                           # this makes it a private hosted zone
          id = module.environment.vpc.id
        }
        records = [
          { name = "db.t2.${local.application_name}", type = "CNAME", ttl = "3600", records = ["t2-oasys-db-a.oasys.hmpps-test.modernisation-platform.internal"] },
          { name = "db.t1.${local.application_name}", type = "CNAME", ttl = "3600", records = ["t1-oasys-db-a.oasys.hmpps-test.modernisation-platform.internal"] },
        ]
        lb_alias_records = [
          # { name = "t2.${local.application_name}", type = "A", lbs_map_key = "public" },
          # { name = "web.t2.${local.application_name}", type = "A", lbs_map_key = "public" },
          # { name = "t1.${local.application_name}", type = "A", lbs_map_key = "public" },
          # { name = "web.t1.${local.application_name}", type = "A", lbs_map_key = "public" },
        ]
      }
    }

    baseline_cloudwatch_log_groups = {
      session-manager-logs = {
        retention_in_days = 7
      }
      cwagent-var-log-messages = {
        retention_in_days = 7
      }
      cwagent-var-log-secure = {
        retention_in_days = 7
      }
      cwagent-windows-system = {
        retention_in_days = 7
      }
      cwagent-oasys-autologoff = {
        retention_in_days = 7
      }
      cwagent-web-logs = {
        retention_in_days = 7
      }
    }
  }
}
