# nomis-production environment settings
locals {

  # baseline config
  production_config = {

    cloudwatch_metric_alarms_dbnames         = []
    cloudwatch_metric_alarms_dbnames_misload = []

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
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "wildcard cert for nomis ${local.environment} domains"
        }
      }
    }

    baseline_ssm_parameters = {
      "prod-nomis-web-a" = local.weblogic_ssm_parameters
      "prod-nomis-web-b" = local.weblogic_ssm_parameters
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
      # blue deployment
      prod-nomis-web-a = merge(local.weblogic_ec2_a, {
        tags = merge(local.weblogic_ec2_a.tags, {
          nomis-environment    = "prod"
          oracle-db-hostname-a = "pnomis-a.production.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "pnomis-b.production.nomis.service.justice.gov.uk"
          oracle-db-name       = "PCNOM"
          is-production        = "true-no-default-backup-workaround"
        })
      })

      # green deployment
      prod-nomis-web-b = merge(local.weblogic_ec2_b, {
        tags = merge(local.weblogic_ec2_b.tags, {
          nomis-environment    = "prod"
          oracle-db-hostname-a = "pnomis-a.production.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "pnomis-b.production.nomis.service.justice.gov.uk"
          oracle-db-name       = "PCNOM"
          is-production        = "true-no-default-backup-workaround"
        })
      })
    }

    baseline_ec2_instances = {
      preprod-nomis-db-2 = merge(local.database_ec2_a, {
        tags = merge(local.database_ec2_a.tags, {
          nomis-environment = "preprod"
          description       = "PreProduction NOMIS MIS and Audit database to replace Azure PPPDL00017"
          oracle-sids       = "PPCNMAUD"
          is-production     = "true-no-default-backup-workaround"
        })
        config = merge(local.database_ec2_a.config, {
          ami_name = "nomis_rhel_7_9_oracledb_11_2_release_2022-10-03T12-51-25.032Z"
        })
        instance = merge(local.database_ec2_a.instance, {
          instance_type = "r6i.2xlarge"
        })
        ebs_volumes = merge(local.database_ec2_a.ebs_volumes, {
          # reduce sdc to 1000 when we move into preprod subscription
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 5120 }
        })
        ebs_volume_config = merge(local.database_ec2_a.ebs_volume_config, {
          data  = { total_size = 4000 }
          flash = { total_size = 1000 }
        })
      })

      prod-nomis-db-2 = merge(local.database_ec2_a, {
        tags = merge(local.database_ec2_a.tags, {
          nomis-environment         = "prod"
          description               = "Production NOMIS MIS and Audit database to replace Azure PDPDL00036 and PDPDL00038"
          oracle-sids               = "CNMAUD"
          fixngo-connection-targets = "10.40.0.136 4903 10.40.129.79 22" # fixngo connection alarm
          is-production             = "true-no-default-backup-workaround"
        })
        instance = merge(local.database_ec2_a.instance, {
          instance_type = "r6i.2xlarge"
        })
        ebs_volumes = merge(local.database_ec2_a.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 3000, iops = 9000 }
        })
        ebs_volume_config = merge(local.database_ec2_a.ebs_volume_config, {
          data  = { total_size = 4000 }
          flash = { total_size = 1000 }
        })
        cloudwatch_metric_alarms = merge(
          local.database_ec2_a.cloudwatch_metric_alarms,
          local.fixngo_connection_cloudwatch_metric_alarms
        )
      })

      prod-nomis-db-3 = merge(local.database_ec2_a, {
        tags = merge(local.database_ec2_a.tags, {
          nomis-environment = "prod"
          description       = "Production NOMIS HA database to replace Azure PDPDL00062"
          oracle-sids       = "PCNOMHA"
          is-production     = "true-no-default-backup-workaround"
        })
        instance = merge(local.database_ec2_a.instance, {
          instance_type = "r6i.4xlarge"
        })
        ebs_volumes = merge(local.database_ec2_a.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 1000 }
        })
        ebs_volume_config = merge(local.database_ec2_a.ebs_volume_config, {
          data  = { total_size = 3000, iops = 3750, throughput = 750 }
          flash = { total_size = 500 }
        })
        cloudwatch_metric_alarms = merge(
          local.database_ec2_a.cloudwatch_metric_alarms,
          local.database_ec2_cloudwatch_metric_alarms_high_priority
        )
      })
    }

    baseline_lbs = {
      private = {
        internal_lb              = true
        enable_delete_protection = false
        force_destroy_bucket     = true
        idle_timeout             = 3600
        public_subnets           = module.environment.subnets["private"].ids
        security_groups          = ["private-lb"]

        listeners = {
          http = local.weblogic_lb_listeners.http

          https = merge(
            local.weblogic_lb_listeners.https, {
              alarm_target_group_names = ["prod-nomis-web-a-http-7777"]
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
                        "c.production.nomis.az.justice.gov.uk",
                        "c.nomis.service.justice.gov.uk",
                        "c.nomis.az.justice.gov.uk",
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

      "hmpps-production.modernisation-platform.internal" = {
        records = [
          { name = "oem.nomis", type = "A", ttl = "300", records = ["10.40.0.136"] },
        ]
      }
      "nomis.service.justice.gov.uk" = {
        # NOTE this top level zone is currently hosted in Azure but
        # will be moved here at some point
        lb_alias_records = [
          { name = "c", type = "A", lbs_map_key = "private" },
        ]
        ns_records = [
          # use this if NS records can be pulled from terrafrom, otherwise use records variable
          { name = "production", ttl = "86400", zone_name = "production.nomis.service.justice.gov.uk" }
        ]
        records = [
          { name = "development", type = "NS", ttl = "86400", records = ["ns-1427.awsdns-50.org", "ns-1956.awsdns-52.co.uk", "ns-294.awsdns-36.com", "ns-788.awsdns-34.net"] },
          { name = "test", type = "NS", ttl = "86400", records = ["ns-1423.awsdns-49.org", "ns-1921.awsdns-48.co.uk", "ns-304.awsdns-38.com", "ns-747.awsdns-29.net"] },
          { name = "preproduction", type = "ns", ttl = "86400", records = ["ns-1200.awsdns-22.org", "ns-1958.awsdns-52.co.uk", "ns-44.awsdns-05.com", "ns-759.awsdns-30.net"] },
        ]
      }
      "production.nomis.az.justice.gov.uk" = {
        lb_alias_records = [
          { name = "prod-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "prod-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c", type = "A", lbs_map_key = "private" },
        ]
      }
      "production.nomis.service.justice.gov.uk" = {
        records = [
          { name = "pnomis", type = "A", ttl = "300", records = ["10.40.3.132"] },
          { name = "pnomis-a", type = "A", ttl = "300", records = ["10.40.3.132"] },
          { name = "pnomis-b", type = "A", ttl = "300", records = ["10.40.67.132"] },
        ]
        lb_alias_records = [
          { name = "prod-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "prod-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c", type = "A", lbs_map_key = "private" },
        ]
      }
    }
  }
}
