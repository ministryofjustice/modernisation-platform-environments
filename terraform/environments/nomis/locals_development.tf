# nomis-development environment settings
locals {
  nomis_development = {
    # vars common across ec2 instances
    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
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
      Ec2Qa11RWeblogicPolicy = {
        description = "Permissions required for QA11R Weblogic EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "ssm:GetParameter",
              "ssm:PutParameter",
            ]
            resources = [
              "arn:aws:ssm:*:*:parameter/oracle/weblogic/qa11r/*",
              "arn:aws:ssm:*:*:parameter/oracle/database/qa11r/weblogic-passwords",
            ]
          }
        ]
      }
    }

    baseline_ssm_parameters = {
      "/oracle/weblogic/qa11r" = local.weblogic_ssm_parameters
      "/oracle/database/qa11r" = local.database_nomis_ssm_parameters
    }
    baseline_secretsmanager_secrets = {
      "/azure" = {
        secrets = {
          sas_token = {}
        }
      }
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

      dev-jumpserver-a = merge(local.jumpserver_ec2, {
        config = merge(local.jumpserver_ec2.config, {
          user_data_raw = base64encode(templatefile("./templates/jumpserver-user-data.yaml.tftpl", {
            ie_compatibility_mode_site_list = join(",", [
              "qa11r-nomis-web-a.development.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
              "qa11r-nomis-web-b.development.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
              "c-qa11r.development.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
            ])
            ie_trusted_domains = join(",", [
              "*.nomis.hmpps-development.modernisation-platform.justice.gov.uk",
              "*.nomis.service.justice.gov.uk",
            ])
            desktop_shortcuts = join(",", [
              "QA11R NOMIS|https://c-qa11r.development.nomis.service.justice.gov.uk/forms/frmservlet?config=tag",
            ])
          }))
        })
      })

      qa11r-nomis-web-a = merge(local.weblogic_ec2, {
        autoscaling_group = merge(local.weblogic_ec2.autoscaling_group, {
          desired_capacity = 0
        })
        cloudwatch_metric_alarms = {}
        config = merge(local.weblogic_ec2.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_*"
          instance_profile_policies = concat(local.weblogic_ec2.config.instance_profile_policies, [
            "Ec2Qa11RWeblogicPolicy",
          ])
        })
        instance = merge(local.weblogic_ec2.instance, {
        })
        user_data_cloud_init = merge(local.weblogic_ec2.user_data_cloud_init, {
          args = merge(local.weblogic_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.weblogic_ec2.tags, {
          nomis-environment    = "qa11r"
          oracle-db-hostname-a = "SDPDL0001.azure.noms.root"
          oracle-db-hostname-b = "none"
          oracle-db-name       = "qa11r"
          deployment           = "blue"
        })
      })

      qa11r-nomis-web-b = merge(local.weblogic_ec2, {
        autoscaling_group = merge(local.weblogic_ec2.autoscaling_group, {
          desired_capacity = 1
        })
        cloudwatch_metric_alarms = {}
        config = merge(local.weblogic_ec2.config, {
          ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
          instance_profile_policies = concat(local.weblogic_ec2.config.instance_profile_policies, [
            "Ec2Qa11RWeblogicPolicy",
          ])
        })
        instance = merge(local.weblogic_ec2.instance, {
        })
        user_data_cloud_init = merge(local.weblogic_ec2.user_data_cloud_init, {
          args = merge(local.weblogic_ec2.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.weblogic_ec2.tags, {
          nomis-environment    = "qa11r"
          oracle-db-hostname-a = "SDPDL0001.azure.noms.root"
          oracle-db-hostname-b = "none"
          oracle-db-name       = "qa11r"
          deployment           = "green"
        })
      })
    }

    baseline_ec2_instances = {
      #dev-nomis-db-1-a = merge(local.database_ec2, {
      #  config = merge(local.database_ec2.config, {
      #    ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-06-23T16-28-48.100Z"
      #    availability_zone = "${local.region}a"
      #  })
      #  ebs_volumes = merge(local.database_ec2.ebs_volumes, {
      #    "/dev/sdb" = { label = "app", size = 100 }
      #    "/dev/sdc" = { label = "app", size = 100 }
      #  })
      #  ebs_volume_config = merge(local.database_ec2.ebs_volume_config, {
      #    data  = { total_size = 500 }
      #    flash = { total_size = 50 }
      #  })
      #  tags = merge(local.database_ec2.tags, {
      #    nomis-environment   = "dev"
      #    description         = "temporary DB to test DB restore"
      #    oracle-sids         = ""
      #  })
      #})
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

        listeners = {
          http = local.weblogic_lb_listeners.http

          http7777 = merge(local.weblogic_lb_listeners.http7777, {
            rules = {
              qa11r-nomis-web-a = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "qa11r-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "qa11r-nomis-web-a.development.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              qa11r-nomis-web-b = {
                priority = 400
                actions = [{
                  type              = "forward"
                  target_group_name = "qa11r-nomis-web-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "qa11r-nomis-web-b.development.nomis.service.justice.gov.uk",
                      "c-qa11r.development.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })

          https = merge(local.weblogic_lb_listeners.https, {
            rules = {
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
                    ]
                  }
                }]
              }
              qa11r-nomis-web-b-http-7777 = {
                priority = 450
                actions = [{
                  type              = "forward"
                  target_group_name = "qa11r-nomis-web-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "qa11r-nomis-web-b.development.nomis.service.justice.gov.uk",
                      "c-qa11r.development.nomis.service.justice.gov.uk",
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
          { name = "dev", type = "CNAME", ttl = "300", records = ["dev-a.development.nomis.service.justice.gov.uk"] },
          { name = "dev-a", type = "CNAME", ttl = "300", records = ["SDPDL0001.azure.noms.root"] },
          { name = "dev-b", type = "CNAME", ttl = "300", records = ["SDPDL0001.azure.noms.root"] },
          { name = "qa11g", type = "CNAME", ttl = "300", records = ["qa11g-a.development.nomis.service.justice.gov.uk"] },
          { name = "qa11g-a", type = "CNAME", ttl = "300", records = ["SDPDL0001.azure.noms.root"] },
          { name = "qa11g-b", type = "CNAME", ttl = "300", records = ["SDPDL0001.azure.noms.root"] },
          { name = "qa11r", type = "CNAME", ttl = "300", records = ["qa11r-a.development.nomis.service.justice.gov.uk"] },
          { name = "qa11r-a", type = "CNAME", ttl = "300", records = ["SDPDL0001.azure.noms.root"] },
          { name = "qa11r-b", type = "CNAME", ttl = "300", records = ["SDPDL0001.azure.noms.root"] },
        ]
        lb_alias_records = [
          # qa11r
          { name = "qa11r-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "qa11r-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-qa11r", type = "A", lbs_map_key = "private" },
        ]
      }
    }
  }
}
