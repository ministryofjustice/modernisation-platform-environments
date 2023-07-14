# environment specific settings
locals {
  test_config = {

    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    baseline_s3_buckets = {
    }

    baseline_ec2_instances = {
      "t2-${local.application_name}-db-a" = local.database_a
      # "t2-${local.application_name}-db-b" = merge(local.database_b, {
      #   user_data_cloud_init  = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags, {
      #     args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_ansible_no_tags.args, {
      #       branch = "oasys/oracle-19c-disk-sector-size-512-change"
      #     })
      #   })
      # })
    }

    baseline_ec2_autoscaling_groups = {
      "t2-${local.application_name}-web-a" = merge(local.webserver_a, {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                  = "oasys_webserver_release_*"
          ssm_parameters_prefix     = "ec2-web-t2/"
          iam_resource_names_prefix = "ec2-web-t2"
        })
        tags = merge(local.webserver_a.tags, {
          description                             = "t2 ${local.application_name} web"
          "${local.application_name}-environment" = "t2"
          oracle-db-hostname                      = "db.t2.oasys.hmpps-test.modernisation-platform.internal" # "T2ODL0009.azure.noms.root"
        })
      })
      # "test-${local.application_name}-bip-a" = local.bip_a

      "test-${local.application_name}-bip-b" = merge(local.bip_b, {
        autoscaling_schedules = {}
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
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso_pagerduty"].acm_default
        tags = {
          description = "cert for t2 ${local.application_name} ${local.environment} domains"
        }
      }
    }

    baseline_lbs = {
      public = {
        load_balancer_type       = "network"
        internal_lb              = false
        access_logs              = false # NLB don't have access logs unless they have a tls listener
        # force_destroy_bucket     = true
        # s3_versioning            = false
        enable_delete_protection = false
        existing_target_groups = {
          "private-lb-https-443" = {
            arn = length(aws_lb_target_group.private-lb-https-443) > 0 ? aws_lb_target_group.private-lb-https-443[0].arn : ""
          }
        }
        idle_timeout    = 60 # 60 is default
        security_groups = [] # no security groups for network load balancers
        public_subnets  = module.environment.subnets["public"].ids
        tags            = local.tags
        listeners = {
          https = {
            port     = 443
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "private-lb-https-443"
            }
          }
        }
      }
      # this routes directly to the webservers
      public2 = { # this is a temporary workaround - we really want public and private load balancers working, but while investigating, get public2 and private2 up
        internal_lb = false
        access_logs              = false
        # s3_versioning            = false
        force_destroy_bucket     = true
        enable_delete_protection = false
        existing_target_groups = {
        }
        idle_timeout             = 60 # 60 is default
        security_groups          = ["private_lb_internal", "private_lb_external"]
        public_subnets           = module.environment.subnets["public"].ids
        tags                     = local.tags

        listeners = {
          https = {
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-2016-08"
            certificate_names_or_arns = ["t2_${local.application_name}_cert"]
            default_action = {
              # type = "fixed-response"
              # fixed_response = {
              #   content_type = "text/plain"
              #   message_body = "T2 - use t2.oasys.service.justice.gov.uk"
              #   status_code  = "200"
              # }
              type              = "forward"
              target_group_name = "t2-${local.application_name}-web-a-pb2-http-8080"
            }
            rules = {
              # t2-web-http-8080 = {
              #   priority = 100
              #   actions = [{
              #     type              = "forward"
              #     target_group_name = "t2-${local.application_name}-web-a-public-http-8080"
              #   }]
              #   conditions = [
              #     {
              #       host_header = {
              #         values = [
              #           "t2.oasys.service.justice.gov.uk",
              #           "*.t2.oasys.service.justice.gov.uk",
              #           "t2-oasys.hmpp-azdt.justice.gov.uk",
              #         ]
              #       }
              #     }
              #   ]
              # }
            }
          }
        }
      }

      public3 = {
        load_balancer_type       = "network"
        internal_lb              = false
        access_logs              = false # NLB don't have access logs unless they have a tls listener
        # force_destroy_bucket     = true
        # s3_versioning            = false
        enable_delete_protection = false
        existing_target_groups = {
          "private2-lb-https-443" = {
            arn = length(aws_lb_target_group.private2-lb-https-443) > 0 ? aws_lb_target_group.private2-lb-https-443[0].arn : ""
          }
        }
        idle_timeout    = 60 # 60 is default
        security_groups = [] # no security groups for network load balancers
        public_subnets  = module.environment.subnets["public"].ids
        tags            = local.tags
        listeners = {
          https = {
            port     = 443
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "private2-lb-https-443"
            }
          }
        }
      }

      private = {
        internal_lb = true
        access_logs              = false
        # s3_versioning            = false
        force_destroy_bucket     = true
        enable_delete_protection = false
        existing_target_groups   = {}
        idle_timeout             = 60 # 60 is default
        security_groups          = ["private_lb_internal", "private_lb_external"]
        public_subnets           = module.environment.subnets["public"].ids
        tags                     = local.tags

        listeners = {
          https = {
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-2016-08"
            certificate_names_or_arns = ["t2_${local.application_name}_cert"]
            default_action = {
              # type = "fixed-response"
              # fixed_response = {
              #   content_type = "text/plain"
              #   message_body = "T2 - use t2.oasys.service.justice.gov.uk"
              #   status_code  = "200"
              # }
              type              = "forward"
              target_group_name = "t2-${local.application_name}-web-a-http-8080"
            }
            rules = {
              # t2-web-http-8080 = {
              #   priority = 100
              #   actions = [{
              #     type              = "forward"
              #     target_group_name = "t2-${local.application_name}-web-a-http-8080"
              #   }]
              #   conditions = [
              #     {
              #       host_header = {
              #         values = [
              #           "t2.oasys.service.justice.gov.uk",
              #           "*.t2.oasys.service.justice.gov.uk",
              #           "t2-oasys.hmpp-azdt.justice.gov.uk",
              #         ]
              #       }
              #     }
              #   ]
              # }
            }
          }
        }
      }
      private2 = { # this is a temporary workaround - we really want public and private load balancers working, but while investigating, get public2 and private2 up
        internal_lb = true
        access_logs              = false
        # s3_versioning            = false
        force_destroy_bucket     = true
        enable_delete_protection = false
        existing_target_groups   = {}
        idle_timeout             = 60 # 60 is default
        security_groups          = ["private_lb_internal", "private_lb_external"]
        public_subnets           = module.environment.subnets["private"].ids
        tags                     = local.tags

        listeners = {
          https = {
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-2016-08"
            certificate_names_or_arns = ["t2_${local.application_name}_cert"]
            default_action = {
              # type = "fixed-response"
              # fixed_response = {
              #   content_type = "text/plain"
              #   message_body = "T2 - use t2.oasys.service.justice.gov.uk"
              #   status_code  = "200"
              # }
              type              = "forward"
              target_group_name = "t2-${local.application_name}-web-a-pv2-http-8080"
            }
            rules = {
              # t2-web-http-8080 = {
              #   priority = 100
              #   actions = [{
              #     type              = "forward"
              #     target_group_name = "t2-${local.application_name}-web-a-http-8080"
              #   }]
              #   conditions = [
              #     {
              #       host_header = {
              #         values = [
              #           "t2.oasys.service.justice.gov.uk",
              #           "*.t2.oasys.service.justice.gov.uk",
              #           "t2-oasys.hmpp-azdt.justice.gov.uk",
              #         ]
              #       }
              #     }
              #   ]
              # }
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
      "${local.application_name}.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "t2", type = "A", lbs_map_key = "public" }, # t2.oasys.service.justice.gov.uk # need to add an ns record to oasys.service.justice.gov.uk -> t2, 
          # { name = "db.t2", type = "A", lbs_map_key = "public" },  # db.t2.oasys.service.justice.gov.uk currently pointing to azure db T2ODL0009
        ]
      }
      # "t1.${local.application_name}.service.justice.gov.uk" = {
      #   lb_alias_records = [
      #     { name = "web", type = "A", lbs_map_key = "public" }, # web.t1.oasys.service.justice.gov.uk # need to add an ns record to oasys.service.justice.gov.uk -> t1, 
      #     { name = "db", type = "A", lbs_map_key = "public" },
      #   ]
      # }
      (module.environment.domains.public.business_unit_environment) = { # hmpps-test.modernisation-platform.service.justice.gov.uk
        # lb_alias_records = [
        #   { name = "t2.${local.application_name}", type = "A", lbs_map_key = "public" },     # t2.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk
        #   { name = "web.t2.${local.application_name}", type = "A", lbs_map_key = "public" }, # web.t2.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk
        #   { name = "db.t2.${local.application_name}", type = "A", lbs_map_key = "public" },
        #   { name = "db.t1.${local.application_name}", type = "A", lbs_map_key = "public" },
        # ]
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
          # { name = "t2.${local.application_name}", type = "A", lbs_map_key = "public" },
          # { name = "web.t2.${local.application_name}", type = "A", lbs_map_key = "public" },
          # { name = "t1.${local.application_name}", type = "A", lbs_map_key = "public" },
          # { name = "web.t1.${local.application_name}", type = "A", lbs_map_key = "public" },
        ]
      }
    }
  }
}
