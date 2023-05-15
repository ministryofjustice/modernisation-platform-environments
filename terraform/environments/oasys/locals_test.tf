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
      # "test-${local.application_name}-web" = local.webserver

      # "t1-${local.application_name}-web" = merge(local.webserver, {
      #   config = merge(module.baseline_presets.ec2_instance.config.default, {
      #     ami_name                  = "${local.application_name}_webserver_release_*"
      #     ssm_parameters_prefix     = "ec2-web-t1/"
      #     iam_resource_names_prefix = "ec2-web-t1"
      #   })
      #   tags = merge(local.webserver.tags, {
      #     description                        = "t1 ${local.application_name} web"
      #     "${local.application_name}-environment"  = "t1"
      #     oracle-db-hostname                 = "db.t1.oasys.hmpps-test.modernisation-platform.internal" # "T1ODL0007.azure.noms.root"
      #   })
      # })

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
      "${local.application_name}_wildcard_cert" = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.${module.environment.domains.public.application_environment}",   # *.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk
          "*.t2.${module.environment.domains.public.application_environment}", # *.t2.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk
          "*.${local.environment}.${module.environment.domains.public.short_name}", # "test.oasys.service.justice.gov.uk"
          "*.t1.${module.environment.domains.public.short_name}",                   # "t1.oasys.service.justice.gov.uk"
          "*.t2.${module.environment.domains.public.short_name}",                   # "t2.oasys.service.justice.gov.uk"
          "*.${local.environment}.${local.application_name}.az.justice.gov.uk",
          "*.t1.${local.application_name}.az.justice.gov.uk",
          "*.t2.${local.application_name}.az.justice.gov.uk",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = {} # module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso"].acm_default
        tags = {
          description = "wildcard cert for ${local.application_name} ${local.environment} domains"
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
              type = "forward"
              # fixed_response = {
              #   content_type = "text/plain"
              #   message_body = "Not implemented"
              #   status_code  = "501"
              # }
              target_group_name = "t2-${local.application_name}-web-http-8080"
            }
            rules = {
              # t1-web-http-8080 = {
              #   priority = 100
              #   actions = [{
              #     type              = "forward"
              #     target_group_name = "t1-${local.application_name}-web-http-8080"
              #   }]
              #   conditions = [
              #     {
              #       host_header = {
              #         values = ["t1.${module.environment.domains.public.short_name}"]
              #       }
              #     },
              #     {
              #       path_pattern = {
              #         values = ["/"]
              #       }
              #     }
              #   ]
              # }
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
                        "web.t2.${module.environment.domains.public.application_environment}",
                        "t2.${module.environment.domains.public.application_environment}"
                      ] # web.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk
                    }
                  }
                ]
              }
            }
          }
        }
      }

    }
    # baseline_route53_zones = { # not sure why this doesn't work
    #   "${module.environment.domains.public.application_environment}" = { # oasys.hmpps-test.modernisation-platform.service.justice.gov.uk
    #     lb_alias_records = [
    #       { name = "t2",     type = "A", lbs_map_key = "public" },
    #       { name = "web.t2", type = "A", lbs_map_key = "public" },
    #       { name = "t1",     type = "A", lbs_map_key = "public" },
    #       { name = "web.t1", type = "A", lbs_map_key = "public" }, 
    #     ]
    #     records = [
    #       { name = "db.t2", type = "A", ttl = "300", records = ["10.101.36.132"] }, # db.t2.oasys.service.justice.gov.uk currently pointing to azure db T2ODL0009
    #       { name = "db.t1", type = "A", ttl = "300", records = ["10.101.6.132"]  }, # db.t1.oasys.service.justice.gov.uk currently pointing to azure db T1ODL0007
    #     ]
    #   }
    # }
    baseline_route53_zones = {
      #
      # public
      #
      "t1.${module.environment.domains.public.short_name}" = { # t1.oasys.service.justice.gov.uk
        records = [
          { name = "db", type = "A", ttl = "300", records = ["10.101.6.132"] }, # db.t1.oasys.service.justice.gov.uk currently pointing to azure db T1ODL0007
        ]
        lb_alias_records = [
          { name = "web", type = "A", lbs_map_key = "public" }, # web.t1.oasys.service.justice.gov.uk
        ]
      }
      "t2.${module.environment.domains.public.short_name}" = { # t2.oasys.service.justice.gov.uk
        records = [
          { name = "db", type = "A", ttl = "300", records = ["10.101.36.132"] }, # db.t2.oasys.service.justice.gov.uk currently pointing to azure db T2ODL0009
        ]
        lb_alias_records = [
          { name = "web", type = "A", lbs_map_key = "public" }, # web.t2.oasys.service.justice.gov.uk
        ]
      }
      "t2.${module.environment.domains.public.application_environment}" = { # t2.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk
        lb_alias_records = [
          { name = "web", type = "A", lbs_map_key = "public" }, # web.t2.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk
        ]
      }
      "${module.environment.domains.public.business_unit_environment}" = { # hmpps-test.modernisation-platform.service.justice.gov.uk
        lb_alias_records = [
          { name = "t2.${local.application_name}", type = "A", lbs_map_key = "public" },     # t2.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk
          { name = "web.t2.${local.application_name}", type = "A", lbs_map_key = "public" }, # web.t2.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk
        ]
      }
      #
      # internal/private
      #
      "${module.environment.domains.internal.business_unit_environment}" = { # hmpps-test.modernisation-platform.internal
        vpc = { # this makes it a private hosted zone
          id = module.environment.vpc.id
        }
        records = [
          { name = "db.t2.${local.application_name}", type = "A", ttl = "300", records = ["10.101.36.132"] }, # db.t2.oasys.hmpps-test.modernisation-platform.internal currently pointing to azure db T2ODL0009
          { name = "db.t1.${local.application_name}", type = "A", ttl = "300", records = ["10.101.6.132"]  }, # db.t1.oasys.hmpps-test.modernisation-platform.internal currently pointing to azure db T1ODL0007
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
