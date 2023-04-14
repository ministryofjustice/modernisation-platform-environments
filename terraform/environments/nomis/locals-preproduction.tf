# nomis-preproduction environment settings
locals {
  nomis_preproduction = {
    # vars common across ec2 instances
    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    # cloud watch log groups
    log_groups = {
      session-manager-logs = {
        retention_days = 90
      }
      cwagent-var-log-messages = {
        retention_days = 30
      }
      cwagent-var-log-secure = {
        retention_days = 90
      }
      cwagent-nomis-autologoff = {
        retention_days = 90
      }
      cwagent-weblogic-logs = {
        retention_days = 30
      }
      cwagent-windows-system = {
        retention_days = 30
      }
    }

    databases = {
      # Naming
      # *-nomis-db-1: NOMIS, NDH, TRDATA
      # *-nomis-db-2: MIS, AUDIT
      # *-nomis-db-3: HA
    }
    weblogics       = {}
    ec2_jumpservers = {}
  }

  # baseline config
  preproduction_config = {
    baseline_ec2_autoscaling_groups = {
      preprod-nomis-web-a = merge(local.ec2_weblogic_zone_a, {
        tags = merge(local.ec2_weblogic_zone_a.tags, {
          oracle-db-hostname = "PPPDL00016.azure.hmpp.root"
          nomis-environment  = "preprod"
          oracle-db-name     = "CNOMPP"
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
        security_groups          = ["private-lb"]

        listeners = {
          https = merge(
            local.lb_weblogic.https, {
              rules = {
                preprod-nomis-web-a-http-7777 = {
                  priority = 200
                  actions = [{
                    type              = "forward"
                    target_group_name = "preprod-nomis-web-a-http-7777"
                  }]
                  conditions = [{
                    host_header = {
                      values = [
                        "preprod-nomis-web-a.nomis.${module.environment.domains.public.business_unit_environment}",
                        "preprod-nomis-web-a.preproduction.nomis.az.justice.gov.uk",
                        "c.preproduction.nomis.az.justice.gov.uk",
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
          { name = "preprod-nomis-web-a.nomis", type = "A", lbs_map_key = "private" },
        ]
      }
      "preproduction.nomis.az.justice.gov.uk" = {
        lb_alias_records = [
          { name = "preprod-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "c", type = "A", lbs_map_key = "private" },
        ]
      }
    }
  }
}
