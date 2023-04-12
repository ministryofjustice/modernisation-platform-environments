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

    # cloud watch log groups
    log_groups = {
      session-manager-logs = {
        retention_days = 400
      }
      cwagent-var-log-messages = {
        retention_days = 90
      }
      cwagent-var-log-secure = {
        retention_days = 400
      }
      cwagent-nomis-autologoff = {
        retention_days = 400
      }
      cwagent-weblogic-logs = {
        retention_days = 30
      }
      cwagent-windows-system = {
        retention_days = 30
      }
    }

    # Add database instances here. They will be created using ec2-database.tf
    databases = {
      # Naming
      # *-nomis-db-1: NOMIS, NDH, TRDATA
      # *-nomis-db-2: MIS, AUDIT
      # *-nomis-db-3: HA

      # NOTE: this is temporarily under prod account while we wait for network connectivity
      preprod-nomis-db-2 = {
        tags = {
          nomis-environment = "preprod"
          server-type       = "nomis-db"
          description       = "PreProduction NOMIS MIS and Audit database to replace Azure PPPDL00017"
          oracle-sids       = "PPCNMAUD"
          monitored         = true
        }
        ami_name  = "nomis_rhel_7_9_oracledb_11_2_release_2022-10-03T12-51-25.032Z"
        ami_owner = "self" # remove this line next time AMI is updated so core-shared-services-production used instead
        instance = {
          instance_type             = "r6i.2xlarge"
          disable_api_termination   = true
          metadata_endpoint_enabled = "enabled"
        }
        # reduce sdc to 1000 when we move into preprod subscription
        ebs_volumes = {
          "/dev/sdb" = { size = 100 }
          "/dev/sdc" = { size = 5120 }
        }
        ebs_volume_config = {
          data  = { total_size = 4000 }
          flash = { total_size = 1000 }
        }
        sns_topic = "nomis_alarms"
      }

      prod-nomis-db-2 = {
        tags = {
          nomis-environment        = "prod"
          server-type              = "nomis-db"
          description              = "Production NOMIS MIS and Audit database to replace Azure PDPDL00036 and PDPDL00038"
          oracle-sids              = "CNMAUD"
          monitored                = true
          fixngo-connection-target = "10.40.0.136"
        }
        ami_name  = "nomis_rhel_7_9_oracledb_11_2_release_2022-10-07T12-48-08.562Z"
        ami_owner = "self" # remove this line next time AMI is updated so core-shared-services-production used instead
        instance = {
          instance_type             = "r6i.2xlarge"
          disable_api_termination   = true
          metadata_endpoint_enabled = "enabled"
        }
        ebs_volumes = {
          "/dev/sdb" = { size = 100 }
          "/dev/sdc" = {
            size = 3000
            iops = 9000
          }
        }
        ebs_volume_config = {
          data  = { total_size = 4000 }
          flash = { total_size = 1000 }
        }
        sns_topic                = "nomis_alarms"
        cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso"].fixngo_connection
      }

      prod-nomis-db-3 = {
        tags = {
          nomis-environment = "prod"
          server-type       = "nomis-db"
          description       = "Production NOMIS HA database to replace Azure PDPDL00062"
          monitored         = true
          oracle-sids       = "PCNOMHA"
        }
        ami_name  = "nomis_rhel_7_9_oracledb_11_2_release_2022-10-07T12-48-08.562Z"
        ami_owner = "self" # remove this line next time AMI is updated so core-shared-services-production used instead
        instance = {
          instance_type             = "r6i.4xlarge"
          disable_api_termination   = true
          metadata_endpoint_enabled = "enabled"
        }
        ebs_volumes = {
          "/dev/sdb" = { size = 100 }
          "/dev/sdc" = { size = 1000 }
        }
        ebs_volume_config = {
          data  = { total_size = 3000, iops = 3750, throughput = 750 }
          flash = { total_size = 500 }
        }
        sns_topic = "nomis_alarms"
      }
    }

    # Add weblogic instances here.  They will be created using the weblogic module
    weblogics       = {}
    ec2_jumpservers = {}
  }

  # baseline config
  production_config = {
    baseline_ec2_autoscaling_groups = {
      prod-nomis-web-a = merge(local.ec2_weblogic_zone_a, {
        tags = merge(local.ec2_weblogic_zone_a.tags, {
          oracle-db-hostname = "PDPDL00035.azure.hmpp.root"
          nomis-environment  = "prod"
          oracle-db-name     = "CNOMP"
        })
      })
    }

    baseline_lbs = {
      private = {
        internal_lb              = true
        enable_delete_protection = false
        existing_target_groups   = local.existing_target_groups
        force_destroy_bucket     = true
        idle_timeout             = 3600
        public_subnets           = module.environment.subnets["private"].ids
        security_groups          = [aws_security_group.public.id]

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
                        "prod-nomis-web-a.${module.environment.domains.public.business_unit_environment}",
                        "prod-nomis-web-a.production.nomis.az.justice.gov.uk",
                        "c.production.nomis.az.justice.gov.uk",
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
      "${module.environment.domains.public.business_unit_environment}" = {
        lb_alias_records = [
          { name = "prod-nomis-web-a.nomis", type = "A", lbs_map_key = "private" },
        ]
      }
      "production.nomis.az.justice.gov.uk" = {
        lb_alias_records = [
          { name = "c", type = "A", lbs_map_key = "private" },
          { name = "prod-nomis-web-a", type = "A", lbs_map_key = "private" },
        ]
      }
    }
  }
}
