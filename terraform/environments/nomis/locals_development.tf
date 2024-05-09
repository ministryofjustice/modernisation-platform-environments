# nomis-development environment settings
locals {

  # cloudwatch monitoring config
  development_cloudwatch_monitoring_options = {}

  # baseline presets config
  development_baseline_presets_options = {
    sns_topics = {
      pagerduty_integrations = {
        dso_pagerduty               = "nomis_nonprod_alarms"
        dba_pagerduty               = "hmpps_shef_dba_non_prod"
        dba_high_priority_pagerduty = "hmpps_shef_dba_non_prod"
      }
    }
  }


  # baseline config
  development_config = {

    baseline_s3_buckets = {
      nomis-audit-archives = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        iam_policies   = module.baseline_presets.s3_iam_policies
      }
      nomis-db-backup-bucket = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        iam_policies   = module.baseline_presets.s3_iam_policies
      }
      syscon-bucket = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        iam_policies   = module.baseline_presets.s3_iam_policies
      }
    }

    baseline_acm_certificates = {
      nomis_wildcard_cert = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.${module.environment.domains.public.application_environment}",
          "*.${local.environment}.nomis.service.justice.gov.uk",
          "*.${local.environment}.nomis.az.justice.gov.uk",
        ]
        cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "wildcard cert for nomis ${local.environment} domains"
        }
      }
    }

    baseline_iam_policies = {
      Ec2DevWeblogicPolicy = {
        description = "Permissions required for dev Weblogic EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/weblogic/dev/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/dev/weblogic-*",
            ]
          }
        ]
      }
      Ec2Qa11GWeblogicPolicy = {
        description = "Permissions required for QA11G Weblogic EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/weblogic/qa11g/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/qa11g/weblogic-*",
            ]
          }
        ]
      }
      Ec2Qa11RWeblogicPolicy = {
        description = "Permissions required for QA11R Weblogic EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/weblogic/qa11r/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/qa11r/weblogic-*",
            ]
          }
        ]
      }
    }

    baseline_secretsmanager_secrets = {
      "/oracle/weblogic/dev"   = local.weblogic_secretsmanager_secrets
      "/oracle/database/dev"   = local.database_nomis_secretsmanager_secrets
      "/oracle/weblogic/qa11g" = local.weblogic_secretsmanager_secrets
      "/oracle/database/qa11g" = local.database_nomis_secretsmanager_secrets
      "/oracle/weblogic/qa11r" = local.weblogic_secretsmanager_secrets
      "/oracle/database/qa11r" = local.database_nomis_secretsmanager_secrets
    }

    baseline_ec2_autoscaling_groups = {

      dev-redhat-rhel79 = {
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "RHEL-7.9_HVM-*"
          ami_owner         = "309956199498"
          availability_zone = null
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-web"]
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "main"
          })
        })
        tags = {
          description = "For testing official RedHat RHEL7.9 image"
          os-type     = "Linux"
          component   = "test"
        }
      }

      dev-base-ol85 = {
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "base_ol_8_5*"
          availability_zone = null
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-web"]
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "main"
          })
        })
        tags = {
          description = "For testing our base OL 8.5 base image"
          ami         = "base_ol_8_5"
          os-type     = "Linux"
          component   = "test"
          server-type = "base-ol85"
        }
      }

      dev-base-rhel85 = {
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "base_rhel_8_5_*"
          availability_zone = null
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-web"]
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "main"
          })
        })
        tags = {
          description = "For testing our base RHEL8.5 base image"
          ami         = "base_rhel_8_5"
          os-type     = "Linux"
          component   = "test"
          server-type = "base-rhel85"
        }
      }

      dev-base-rhel79 = {
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "base_rhel_7_9_*"
          availability_zone = null
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-web"]
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "main"
          })
        })
        tags = {
          description = "For testing our base RHEL7.9 base image"
          ami         = "base_rhel_7_9"
          os-type     = "Linux"
          component   = "test"
          server-type = "base-rhel79"
        }
      }

      dev-base-rhel610 = {
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "base_rhel_6_10*"
          availability_zone = null
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default_rhel6, {
          vpc_security_group_ids = ["private-web"]
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "main"
          })
        })
        tags = {
          description = "For testing our base RHEL6.10 base image"
          ami         = "base_rhel_6_10"
          os-type     = "Linux"
          component   = "test"
          server-type = "base-rhel610"
        }
      }

      dev-nomis-client-a = local.jumpserver_ec2
    }

    baseline_ec2_instances = {

      dev-nomis-db-1-a = merge(local.database_ec2, {
        config = merge(local.database_ec2.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "${local.region}a"
          instance_profile_policies = concat(local.weblogic_ec2.config.instance_profile_policies, [
            "Ec2DevWeblogicPolicy",
            "Ec2Qa11GWeblogicPolicy",
            "Ec2Qa11RWeblogicPolicy",
          ])
        })
        ebs_volumes = merge(local.database_ec2.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 100 }
        })
        ebs_volume_config = merge(local.database_ec2.ebs_volume_config, {
          data  = { total_size = 500 }
          flash = { total_size = 50 }
        })
        tags = merge(local.database_ec2.tags, {
          nomis-environment   = "dev"
          description         = "syscon nomis dev and qa databases"
          instance-scheduling = "skip-scheduling"
          oracle-sids         = ""
        })
      })

      dev-nomis-web-a = merge(local.weblogic_ec2, {
        cloudwatch_metric_alarms = {}
        config = merge(local.weblogic_ec2.config, {
          availability_zone = "${local.region}a"
          instance_profile_policies = concat(local.weblogic_ec2.config.instance_profile_policies, [
            "Ec2DevWeblogicPolicy",
          ])
        })
        instance = merge(local.weblogic_ec2.instance, {
          instance_type = "t2.large"
          tags = {
            backup-plan = "daily-and-weekly"
          }
        })
        route53_records = module.baseline_presets.ec2_instance.route53_records.internal_and_external
        user_data_cloud_init = merge(local.weblogic_ec2.user_data_cloud_init, {
          args = merge(local.weblogic_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.weblogic_ec2.tags, {
          instance-scheduling  = "skip-scheduling"
          nomis-environment    = "dev"
          oracle-db-hostname-a = "dev-nomis-db-1-a"
          oracle-db-hostname-b = "none"
          oracle-db-name       = "dev"
        })
      })

      qa11g-nomis-web-a = merge(local.weblogic_ec2, {
        cloudwatch_metric_alarms = {}
        config = merge(local.weblogic_ec2.config, {
          availability_zone = "${local.region}a"
          instance_profile_policies = concat(local.weblogic_ec2.config.instance_profile_policies, [
            "Ec2Qa11GWeblogicPolicy",
          ])
        })
        instance = merge(local.weblogic_ec2.instance, {
          instance_type = "t2.large"
          tags = {
            backup-plan = "daily-and-weekly"
          }
        })
        route53_records = module.baseline_presets.ec2_instance.route53_records.internal_and_external
        user_data_cloud_init = merge(local.weblogic_ec2.user_data_cloud_init, {
          args = merge(local.weblogic_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.weblogic_ec2.tags, {
          instance-scheduling  = "skip-scheduling"
          nomis-environment    = "qa11g"
          oracle-db-hostname-a = "dev-nomis-db-1-a"
          oracle-db-hostname-b = "none"
          oracle-db-name       = "qa11g"
        })
      })

      qa11r-nomis-web-a = merge(local.weblogic_ec2, {
        cloudwatch_metric_alarms = {}
        config = merge(local.weblogic_ec2.config, {
          availability_zone = "${local.region}a"
          instance_profile_policies = concat(local.weblogic_ec2.config.instance_profile_policies, [
            "Ec2Qa11RWeblogicPolicy",
          ])
        })
        instance = merge(local.weblogic_ec2.instance, {
          instance_type = "t2.large"
          tags = {
            backup-plan = "daily-and-weekly"
          }
        })
        route53_records = module.baseline_presets.ec2_instance.route53_records.internal_and_external
        user_data_cloud_init = merge(local.weblogic_ec2.user_data_cloud_init, {
          args = merge(local.weblogic_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.weblogic_ec2.tags, {
          instance-scheduling  = "skip-scheduling"
          nomis-environment    = "qa11r"
          oracle-db-hostname-a = "dev-nomis-db-1-a"
          oracle-db-hostname-b = "none"
          oracle-db-name       = "qa11r"
        })
      })

      dev-nomis-build-a = {
        cloudwatch_metric_alarms = {}
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "base_rhel_7_9_2024-03-01T00-00-34.773Z"
          availability_zone = "${local.region}a"
          instance_profile_policies = concat(local.weblogic_ec2.config.instance_profile_policies, [
            "Ec2DevWeblogicPolicy",
            "Ec2Qa11GWeblogicPolicy",
            "Ec2Qa11RWeblogicPolicy",
          ])
        })
        ebs_volumes = {
          "/dev/sdb" = { label = "app", size = 100, type = "gp3" } # /u01
          "/dev/sdc" = { label = "app", size = 100, type = "gp3" } # /u02
        }
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type          = "t3.medium"
          vpc_security_group_ids = ["private-web"]
          tags = {
            backup-plan = "daily-and-weekly"
          }
        })
        route53_records = module.baseline_presets.ec2_instance.route53_records.internal_and_external
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "main"
          })
        })
        tags = {
          description         = "Syscon build and release server"
          ami                 = "base_rhel_7_9"
          instance-scheduling = "skip-scheduling"
          os-type             = "Linux"
          component           = "build"
          server-type         = "nomis-build"
        }
      }
    }

    baseline_lbs = {
      # AWS doesn't let us call it internal
      private = {
        internal_lb              = true
        enable_delete_protection = false
        force_destroy_bucket     = true
        idle_timeout             = 3600
        subnets                  = module.environment.subnets["private"].ids
        security_groups          = ["private-lb"]

        instance_target_groups = {
          dev-nomis-web-a-http-7777 = merge(local.weblogic_target_group_http_7777, {
            attachments = [
              { ec2_instance_name = "dev-nomis-web-a" },
            ]
          })
          qa11g-nomis-web-a-http-7777 = merge(local.weblogic_target_group_http_7777, {
            attachments = [
              { ec2_instance_name = "qa11g-nomis-web-a" },
            ]
          })
          qa11r-nomis-web-a-http-7777 = merge(local.weblogic_target_group_http_7777, {
            attachments = [
              { ec2_instance_name = "qa11r-nomis-web-a" },
            ]
          })
        }

        listeners = {
          http = local.weblogic_lb_listeners.http

          https = merge(local.weblogic_lb_listeners.https, {
            rules = {
              dev-nomis-web-a-http-7777 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "dev-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "dev-nomis-web-a.development.nomis.service.justice.gov.uk",
                      "c-dev.development.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              qa11g-nomis-web-a-http-7777 = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "qa11g-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "qa11g-nomis-web-a.development.nomis.service.justice.gov.uk",
                      "c-qa11g.development.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              qa11r-nomis-web-a-http-7777 = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "qa11r-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "qa11r-nomis-web-a.development.nomis.service.justice.gov.uk",
                      "c-qa11r.development.nomis.service.justice.gov.uk",
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
                    message_body = file("templates/maintenance.html")
                    status_code  = "200"
                  }
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "dev-nomis-web-b.development.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })
        }
      }
    }

    baseline_route53_zones = {
      "development.hmpps-test.modernisation-platform.service.justice.gov.uk" = {
        records = [
        ]
      }
      "development.nomis.az.justice.gov.uk" = {
        lb_alias_records = [
        ]
      }
      "development.nomis.service.justice.gov.uk" = {
        records = [
          # SYSCON
          { name = "dev", type = "CNAME", ttl = "300", records = ["dev-nomis-db-1-a.nomis.hmpps-development.modernisation-platform.service.justice.gov.uk"] },
          { name = "qa11g", type = "CNAME", ttl = "300", records = ["dev-nomis-db-1-a.nomis.hmpps-development.modernisation-platform.service.justice.gov.uk"] },
          { name = "qa11r", type = "CNAME", ttl = "300", records = ["dev-nomis-db-1-a.nomis.hmpps-development.modernisation-platform.service.justice.gov.uk"] },
        ]
        lb_alias_records = [
          # dev
          { name = "dev-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "dev-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-dev", type = "A", lbs_map_key = "private" },
          # qa11g
          { name = "qa11g-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "qa11g-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-qa11g", type = "A", lbs_map_key = "private" },
          # qa11r
          { name = "qa11r-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "qa11r-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-qa11r", type = "A", lbs_map_key = "private" },
        ]
      }
    }
  }
}
