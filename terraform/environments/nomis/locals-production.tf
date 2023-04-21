# nomis-production environment settings
locals {
  nomis_production = {
    # production SNS channel for alarms
    sns_topic = "nomis_alarms"
    # Details of OMS Manager in FixNGo (only needs defining if databases in the environment are managed)
    database_oracle_manager = {
      oms_ip_address = "10.40.0.136"
      oms_hostname   = "oem"
    }
    # vars common across ec2 instances
    ec2_common = {
      patch_approval_delay_days = 7
      patch_day                 = "THU"
    }

    # Add database instances here. They will be created using ec2-database.tf
    databases = {}

    # Add weblogic instances here.  They will be created using the weblogic module
    weblogics       = {}
    ec2_jumpservers = {}
  }

  # baseline config
  production_config = {

    baseline_acm_certificates = {
      nomis_wildcard_cert = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.${module.environment.domains.public.application_environment}",
          "*.${local.environment}.nomis.service.justice.gov.uk",
          "*.${local.environment}.nomis.az.justice.gov.uk",
          "*.nomis.service.justice.gov.uk",
          "*.nomis.az.justice.gov.uk",
        ]
        external_validation_records_created = true
        # cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso"].acm_default
        tags = {
          description = "wildcard cert for nomis ${local.environment} domains"
        }
      }
    }

    baseline_cloudwatch_log_groups = {
      session-manager-logs = {
        retention_in_days = 400
      }
      cwagent-var-log-messages = {
        retention_in_days = 90
      }
      cwagent-var-log-secure = {
        retention_in_days = 400
      }
      cwagent-windows-system = {
        retention_in_days = 90
      }
      cwagent-nomis-autologoff = {
        retention_in_days = 400
      }
      cwagent-weblogic-logs = {
        retention_in_days = 90
      }
    }

    baseline_ec2_autoscaling_groups = {
      prod-nomis-web-a = merge(local.ec2_weblogic_a, {
        tags = merge(local.ec2_weblogic_a.tags, {
          oracle-db-hostname = "PDPDL00035.azure.hmpp.root"
          nomis-environment  = "prod"
          oracle-db-name     = "CNOMP"
        })
        autoscaling_group = merge(local.ec2_weblogic_a.autoscaling_group, {
          desired_capacity = 0
        })
      })
      prod-nomis-web-b = merge(local.ec2_weblogic_b, {
        tags = merge(local.ec2_weblogic_b.tags, {
          oracle-db-hostname = "PDPDL00035.azure.hmpp.root"
          nomis-environment  = "prod"
          oracle-db-name     = "CNOMP"
        })
        cloudwatch_metric_alarms = {}
      })
    }

    baseline_ec2_instances = {
      preprod-nomis-db-2 = merge(local.database_zone_a, {
        tags = merge(local.database_zone_a.tags, {
          nomis-environment = "preprod"
          description       = "PreProduction NOMIS MIS and Audit database to replace Azure PPPDL00017"
          oracle-sids       = "PPCNMAUD"
        })
        config = merge(local.database_zone_a.config, {
          ami_name = "nomis_rhel_7_9_oracledb_11_2_release_2022-10-03T12-51-25.032Z"
        })
        instance = merge(local.database_zone_a.instance, {
          instance_type = "r6i.2xlarge"
        })
        ebs_volumes = merge(local.database_zone_a.ebs_volumes, {
          # reduce sdc to 1000 when we move into preprod subscription
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 5120 }
        })
        ebs_volume_config = merge(local.database_zone_a.ebs_volume_config, {
          data  = { total_size = 4000 }
          flash = { total_size = 1000 }
        })
      })

      prod-nomis-db-2 = merge(local.database_zone_a, {
        tags = merge(local.database_zone_a.tags, {
          nomis-environment        = "prod"
          description              = "Production NOMIS MIS and Audit database to replace Azure PDPDL00036 and PDPDL00038"
          oracle-sids              = "CNMAUD"
          fixngo-connection-target = "10.40.0.136"
        })
        instance = merge(local.database_zone_a.instance, {
          instance_type = "r6i.2xlarge"
        })
        ebs_volumes = merge(local.database_zone_a.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 3000, iops = 9000 }
        })
        ebs_volume_config = merge(local.database_zone_a.ebs_volume_config, {
          data  = { total_size = 4000 }
          flash = { total_size = 1000 }
        })
        # cloudwatch_metric_alarms = merge(
        #   local.database_zone_a.cloudwatch_metric_alarms,
        #   module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso"].fixngo_connection
        # )
      })

      prod-nomis-db-3 = merge(local.database_zone_a, {
        tags = merge(local.database_zone_a.tags, {
          nomis-environment = "prod"
          description       = "Production NOMIS HA database to replace Azure PDPDL00062"
          oracle-sids       = "PCNOMHA"
        })
        instance = merge(local.database_zone_a.instance, {
          instance_type = "r6i.4xlarge"
        })
        ebs_volumes = merge(local.database_zone_a.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 1000 }
        })
        ebs_volume_config = merge(local.database_zone_a.ebs_volume_config, {
          data  = { total_size = 3000, iops = 3750, throughput = 750 }
          flash = { total_size = 500 }
        })
      })
    }

    baseline_lbs = {
      private = {
        internal_lb              = true
        enable_delete_protection = false
        force_destroy_bucket     = true
        idle_timeout             = 3600
        public_subnets           = module.environment.subnets["private"].ids
        security_groups = [
          aws_security_group.public.id, # TODO: remove once weblogic servers refreshed
          "private-lb"
        ]

        listeners = {
          https = merge(
            local.lb_weblogic.https, {
              rules = {
                prod-nomis-web-a-http-7777 = {
                  priority = 200
                  actions = [{
                    type              = "forward"
                    target_group_name = "prod-nomis-web-a-http-7777"
                  }]
                  conditions = [{
                    host_header = {
                      values = [
                        "prod-nomis-web-a.production.nomis.az.justice.gov.uk",
                        "prod-nomis-web-a.production.nomis.service.justice.gov.uk",
                      ]
                    }
                  }]
                }
                prod-nomis-web-b-http-7777 = {
                  priority = 400
                  actions = [{
                    type              = "forward"
                    target_group_name = "prod-nomis-web-b-http-7777"
                  }]
                  conditions = [{
                    host_header = {
                      values = [
                        "prod-nomis-web-b.production.nomis.az.justice.gov.uk",
                        "prod-nomis-web-b.production.nomis.service.justice.gov.uk",
                        "c.production.nomis.az.justice.gov.uk",
                        "c.production.nomis.service.justice.gov.uk",
                        "c.nomis.az.justice.gov.uk",
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
      "nomis.service.justice.gov.uk" = {
      }
      "production.nomis.az.justice.gov.uk" = {
        lb_alias_records = [
          { name = "prod-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "prod-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c", type = "A", lbs_map_key = "private" },
        ]
      }
      "production.nomis.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "prod-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "prod-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c", type = "A", lbs_map_key = "private" },
        ]
      }
    }
  }
}
