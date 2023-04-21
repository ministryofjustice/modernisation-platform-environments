# nomis-preproduction environment settings
locals {
  nomis_preproduction = {
    # vars common across ec2 instances
    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
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

    baseline_acm_certificates = {
      nomis_wildcard_cert = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.${module.environment.domains.public.application_environment}",
          "*.${local.environment}.nomis.service.justice.gov.uk",
          "*.${local.environment}.nomis.az.justice.gov.uk",
          "*.pp-nomis.az.justice.gov.uk",
          "*.lsast-nomis.az.justice.gov.uk",
        ]
        external_validation_records_created = true
        # cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso"].acm_default
        tags = {
          description = "wildcard cert for nomis ${local.environment} domains"
        }
      }
    }

    baseline_ec2_autoscaling_groups = {
      preprod-nomis-web-a = merge(local.ec2_weblogic_a, {
        tags = merge(local.ec2_weblogic_a.tags, {
          oracle-db-hostname = "PPPDL00016.azure.hmpp.root"
          nomis-environment  = "preprod"
          oracle-db-name     = "CNOMPP"
        })
      })
      preprod-nomis-web-b = merge(local.ec2_weblogic_b, {
        tags = merge(local.ec2_weblogic_b.tags, {
          oracle-db-hostname = "PPPDL00016.azure.hmpp.root"
          nomis-environment  = "preprod"
          oracle-db-name     = "CNOMPP"
        })
        cloudwatch_metric_alarms = {}
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
                preprod-nomis-web-a-http-7777 = {
                  priority = 200
                  actions = [{
                    type              = "forward"
                    target_group_name = "preprod-nomis-web-a-http-7777"
                  }]
                  conditions = [{
                    host_header = {
                      values = [
                        "preprod-nomis-web-a.preproduction.nomis.az.justice.gov.uk",
                        "preprod-nomis-web-a.preproduction.nomis.service.justice.gov.uk",
                        "c.preproduction.nomis.az.justice.gov.uk",
                        "c.preproduction.nomis.service.justice.gov.uk",
                        "c.pp-nomis.service.justice.gov.uk",
                      ]
                    }
                  }]
                }
                preprod-nomis-web-b-http-7777 = {
                  priority = 400
                  actions = [{
                    type              = "forward"
                    target_group_name = "preprod-nomis-web-b-http-7777"
                  }]
                  conditions = [{
                    host_header = {
                      values = [
                        "preprod-nomis-web-b.preproduction.nomis.az.justice.gov.uk",
                        "preprod-nomis-web-b.preproduction.nomis.service.justice.gov.uk",
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
      "preproduction.nomis.az.justice.gov.uk" = {
        lb_alias_records = [
          { name = "preprod-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "preprod-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c", type = "A", lbs_map_key = "private" },
        ]
      }
      "preproduction.nomis.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "preprod-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "preprod-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c", type = "A", lbs_map_key = "private" },
        ]
      }
    }
  }
}
