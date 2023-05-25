# environment specific settings
locals {
  test_config = {

    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    baseline_s3_buckets = {
    }

    baseline_ec2_autoscaling_groups = {
      "t2-${local.application_name}-web" = merge(local.webserver, {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                  = "oasys_webserver_release_*"
          ssm_parameters_prefix     = "ec2-web-t2/"
          iam_resource_names_prefix = "ec2-web-t2"
        })
        tags = merge(local.webserver.tags, {
          description                             = "t2 ${local.application_name} web"
          "${local.application_name}-environment" = "t2"
          oracle-db-hostname                      = "db.t2.oasys.hmpps-test.modernisation-platform.internal" # "T2ODL0009.azure.noms.root"
        })
      })
    }

    baseline_acm_certificates = {
      "t2_${local.application_name}_cert" = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = "t2.oasys.service.justice.gov.uk"
        subject_alternate_names = [
          "*.t2.oasys.service.justice.gov.uk",
          "t2-oasys.hmpp-azdt.justice.gov.uk",
        ]
        external_validation_records_created = false
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso_pagerduty"].acm_default
        tags = {
          description = "cert for t2 ${local.application_name} ${local.environment} domains"
        }
      }
    }

    baseline_lbs = {
      private = {
        internal_lb              = true
        enable_delete_protection = false
        existing_target_groups   = {}
        idle_timeout             = 60 # 60 is default
        security_groups          = ["private"]
        public_subnets           = module.environment.subnets["private"].ids
        tags                     = local.tags

        listeners = {
          https = {
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-2016-08"
            certificate_names_or_arns = ["application_environment_wildcard_cert"]
            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "Not implemented"
                status_code  = "501"
              }
            }
            rules = {
            }
          }
        }
      }
      public = {
        internal_lb              = false
        enable_delete_protection = false
        existing_target_groups   = {}
        idle_timeout             = 60 # 60 is default
        security_groups          = ["public"]
        public_subnets           = module.environment.subnets["public"].ids
        tags                     = local.tags

        listeners = {
          https = {
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-2016-08"
            certificate_names_or_arns = ["application_environment_wildcard_cert"]
            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "Not implemented"
                status_code  = "501"
              }
            }
            rules = {
              t2-web-http-8080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-${local.application_name}-web-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "web.t2.${module.environment.domains.public.application_environment}", # web.t2.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk
                        "t2.${module.environment.domains.public.application_environment}",     #    web.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk
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
      # "t2.${local.application_name}.service.justice.gov.uk" = {
      #   lb_alias_records = [
      #     { name = "web", type = "A", lbs_map_key = "public" }, # web.t2.oasys.service.justice.gov.uk # need to add an ns record to oasys.service.justice.gov.uk -> t2, 
      #     { name = "db", type = "A", lbs_map_key = "public" },  # db.t2.oasys.service.justice.gov.uk currently pointing to azure db T2ODL0009
      #   ]
      # }
      # "t1.${local.application_name}.service.justice.gov.uk" = {
      #   lb_alias_records = [
      #     { name = "web", type = "A", lbs_map_key = "public" }, # web.t1.oasys.service.justice.gov.uk # need to add an ns record to oasys.service.justice.gov.uk -> t1, 
      #     { name = "db", type = "A", lbs_map_key = "public" },
      #   ]
      # }
      (module.environment.domains.public.business_unit_environment) = { # hmpps-test.modernisation-platform.service.justice.gov.uk
        lb_alias_records = [
          { name = "t2.${local.application_name}", type = "A", lbs_map_key = "public" },     # t2.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk
          { name = "web.t2.${local.application_name}", type = "A", lbs_map_key = "public" }, # web.t2.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk
          { name = "db.t2.${local.application_name}", type = "A", lbs_map_key = "public" },
          { name = "db.t1.${local.application_name}", type = "A", lbs_map_key = "public" },
        ]
      }
      #
      # internal/private
      #
      (module.environment.domains.internal.business_unit_environment) = { # hmpps-test.modernisation-platform.internal
        vpc = {                                                           # this makes it a private hosted zone
          id = module.environment.vpc.id
        }
        records = [
          { name = "db.t2.${local.application_name}", type = "A", ttl = "300", records = ["10.101.36.132"] }, # db.t2.oasys.hmpps-test.modernisation-platform.internal currently pointing to azure db T2ODL0009
          { name = "db.t1.${local.application_name}", type = "A", ttl = "300", records = ["10.101.6.132"] },  # db.t1.oasys.hmpps-test.modernisation-platform.internal currently pointing to azure db T1ODL0007
        ]
        lb_alias_records = [
          { name = "t2.${local.application_name}", type = "A", lbs_map_key = "public" },
          { name = "web.t2.${local.application_name}", type = "A", lbs_map_key = "public" },
          { name = "t1.${local.application_name}", type = "A", lbs_map_key = "public" },
          { name = "web.t1.${local.application_name}", type = "A", lbs_map_key = "public" },
        ]
      }
    }
  }
}
