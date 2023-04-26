# nomis-preproduction environment settings
locals {

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
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["nomis_pagerduty"].acm_default
        tags = {
          description = "wildcard cert for nomis ${local.environment} domains"
        }
      }
    }

    baseline_ec2_autoscaling_groups = {
      preprod-nomis-web-a = merge(local.weblogic_ec2_a, {
        tags = merge(local.weblogic_ec2_a.tags, {
          nomis-environment    = "preprod"
          oracle-db-hostname-a = "ppnomis-a.preproduction.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "ppnomis-b.preproduction.nomis.service.justice.gov.uk"
          oracle-db-name       = "PPCNOM"
        })
        autoscaling_group = merge(local.weblogic_ec2_a.autoscaling_group, {
          desired_capacity = 1
        })
        cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["nomis_pagerduty"].weblogic
      })
      preprod-nomis-web-b = merge(local.weblogic_ec2_b, {
        tags = merge(local.weblogic_ec2_b.tags, {
          oracle-db-hostname = "PPPDL00016.azure.hmpp.root"
          nomis-environment  = "preprod"
          oracle-db-name     = "CNOMPP"
        })
        autoscaling_group = merge(local.weblogic_ec2_a.autoscaling_group, {
          desired_capacity = 0
        })
        # cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["nomis_pagerduty"].weblogic
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
            local.weblogic_lb_listeners.https, {
              alarm_target_group_names = ["preprod-nomis-web-b-http-7777"]
              cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["nomis_pagerduty"].lb_default
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
        records = [
          { name = "ppnomis", type = "A", ttl = "300", records = ["10.40.37.132"] },
          { name = "ppnomis-a", type = "A", ttl = "300", records = ["10.40.37.132"] },
          { name = "ppnomis-b", type = "A", ttl = "300", records = ["10.40.37.132"] },
        ]
        lb_alias_records = [
          { name = "preprod-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "preprod-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c", type = "A", lbs_map_key = "private" },
        ]
      }
    }
  }
}
