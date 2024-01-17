# nomis-production environment settings
locals {

  # baseline config
  production_config = {

    baseline_ec2_instances = {
      # database servers
      pd-cafm-db-b = merge(local.defaults_database_ec2, {
        config = merge(local.defaults_database_ec2.config, {
          ami_name          = "pd-cafm-db-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_database_ec2.instance, {
          instance_type = "r6i.4xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 500 }
          "/dev/sdc"  = { type = "gp3", size = 112 }
          "/dev/sdd"  = { type = "gp3", size = 500 }
          "/dev/sde"  = { type = "gp3", size = 50 }
          "/dev/sdf"  = { type = "gp3", size = 85 }
          "/dev/sdg"  = { type = "gp3", size = 100 }
        }
        tags = merge(local.defaults_database_ec2.tags, {
          description       = "copy of PDFDW0031 SQL resilient Server"
          app-config-status = "pending"
          ami               = "pd-cafm-db-b"
        })
      })

      # web servers
      pd-cafm-w-38-b = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-cafm-w-38-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "t3.large"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 100 }
        }
        tags = {
          description       = "CAFM Web Training migrated server PDFWW3QCP660001"
          app-config-status = "pending"
          os-type           = "Windows"
          ami               = "pd-cafm-w-38-b"
          component         = "web"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })
    }
    # baseline_lbs = {
    #   private = {
    #     internal_lb                      = true
    #     enable_delete_protection         = false
    #     load_balancer_type               = "application"
    #     idle_timeout                     = 3600
    #     security_groups                  = ["loadbalancer"]
    #     subnets                          = module.environment.subnets["private"].ids
    #     enable_cross_zone_load_balancing = true

    #     instance_target_groups = {
    #       web-24-80 = {
    #         port     = 80
    #         protocol = "HTTP"
    #         health_check = {
    #           enabled             = true
    #           path                = "/RDWeb"
    #           healthy_threshold   = 3
    #           unhealthy_threshold = 5
    #           timeout             = 5
    #           interval            = 30
    #           matcher             = "200-399"
    #           port                = 80
    #         }
    #         stickiness = {
    #           enabled = true
    #           type    = "lb_cookie"
    #         }
    #         attachments = [
    #           { ec2_instance_name = "pd-cafm-w-2-b" }, # FIXME: instance name needs checking
    #           { ec2_instance_name = "pd-cafm-w-4-a" }, # FIXME: instance name needs checking
    #         ]
    #       }
    #       web-56-80 = {
    #         port     = 80
    #         protocol = "HTTP"
    #         health_check = {
    #           enabled             = true
    #           path                = "/"
    #           healthy_threshold   = 3
    #           unhealthy_threshold = 5
    #           timeout             = 5
    #           interval            = 30
    #           matcher             = "200-399"
    #           port                = 80
    #         }
    #         stickiness = {
    #           enabled = true
    #           type    = "lb_cookie"
    #         }
    #         attachments = [
    #           { ec2_instance_name = "pp-cafm-w-6-b" }, # FIXME: instance name needs checking
    #           { ec2_instance_name = "pp-cafm-w-5-a" }, # FIXME: instance name needs checking
    #         ]
    #       }
    #       web-3637-80 = {
    #         port     = 80
    #         protocol = "HTTP"
    #         health_check = {
    #           enabled             = true
    #           path                = "/"
    #           healthy_threshold   = 3
    #           unhealthy_threshold = 5
    #           timeout             = 5
    #           interval            = 30
    #           matcher             = "200-399"
    #           port                = 80
    #         }
    #         stickiness = {
    #           enabled = true
    #           type    = "lb_cookie"
    #         }
    #         attachments = [
    #           { ec2_instance_name = "pp-cafm-w-36-b" }, # FIXME: instance name needs checking
    #           { ec2_instance_name = "pp-cafm-w-37-a" }, # FIXME: instance name needs checking
    #         ]
    #       }
    #       web-38-80 = {
    #         port     = 80
    #         protocol = "HTTP"
    #         health_check = {
    #           enabled             = true
    #           path                = "/"
    #           healthy_threshold   = 3
    #           unhealthy_threshold = 5
    #           timeout             = 5
    #           interval            = 30
    #           matcher             = "200-399"
    #           port                = 80
    #         }
    #         stickiness = {
    #           enabled = true
    #           type    = "lb_cookie"
    #         }
    #         attachments = [
    #           { ec2_instance_name = "pp-cafm-w-38-b" }, # FIXME: instance name needs checking
    #         ]
    #       } 
    #     }
    #     listeners = {
    #       http = {
    #         port     = 80
    #         protocol = "HTTP"
    #         default_action = {
    #           type = "redirect"
    #           redirect = {
    #             port        = 443
    #             protocol    = "HTTPS"
    #             status_code = "HTTP_301"
    #           }
    #         }
    #       }
    #       https = {
    #         port                      = 443
    #         protocol                  = "HTTPS"
    #         ssl_policy                = "ELBSecurityPolicy-2016-08"
    #         certificate_names_or_arns = ["planetfm_wildcard_cert"]
    #         default_action = {
    #           type = "fixed-response"
    #           fixed_response = {
    #             content_type = "text/plain"
    #             message_body = "Not implemented"
    #             status_code  = "501"
    #           }
    #         }
    #         rules = {
    #           web-23-80 = {
    #             priority = 2380
    #             actions = [{
    #               type              = "forward"
    #               target_group_name = "web-23-80"
    #             }]
    #             conditions = [{
    #               host_header = {
    #                 values = [
    #                   "cafmtx.planetfm.service.justice.gov.uk",
    #                   "cafmtx.az.justice.gov.uk",
    #                 ]
    #               }
    #             }]
    #           }
    #           web-45-80 = {
    #             priority = 4580
    #             actions = [{
    #               type              = "forward"
    #               target_group_name = "web-45-80"
    #             }]
    #             conditions = [{
    #               host_header = {
    #                 values = [
    #                   "cafmwebx.planetfm.service.justice.gov.uk",
    #                   "cafmwebx.az.justice.gov.uk",
    #                 ]
    #               }
    #             }]
    #           }
    #           web-3637-80 = {
    #             priority = 3637
    #             actions = [{
    #               type              = "forward"
    #               target_group_name = "web-3637-80"
    #             }]
    #             conditions = [{
    #               host_header = {
    #                 values = [
    #                   "cafmwebx2.planetfm.service.justice.gov.uk",
    #                   "cafmwebx2.az.justice.gov.uk",
    #                 ]
    #               }
    #             }]
    #           }
    #           web-38-80 = {
    #             priority = 38
    #             actions = [{
    #               type              = "forward"
    #               target_group_name = "web-38-80"
    #             }]
    #             conditions = [{
    #               host_header = {
    #                 values = [
    #                   "cafmtrainweb.planetfm.service.justice.gov.uk",
    #                   "cafmtrainweb.az.justice.gov.uk",
    #                 ]
    #               }
    #             }]
    #           }
    #         }
    #       }
    #     }
    #   }
    # }
    baseline_route53_zones = {
      "planetfm.service.justice.gov.uk" = {
        records = [
          { name = "test", type = "NS", ttl = "86400", records = ["ns-1128.awsdns-13.org", "ns-2027.awsdns-61.co.uk", "ns-854.awsdns-42.net", "ns-90.awsdns-11.com"] },
          { name = "pp", type = "NS", ttl = "86400", records = ["ns-1407.awsdns-47.org", "ns-1645.awsdns-13.co.uk", "ns-63.awsdns-07.com", "ns-730.awsdns-27.net"] },
        ]
        # lb_alias_records = [
        #   { name = "cafmtx", type = "A", lbs_map_key = "private" },
        #   { name = "cafmwebx", type = "A", lbs_map_key = "private" },
        #   { name = "cafmwebx2", type = "A", lbs_map_key = "private" },
        #   { name = "cafmtrainweb", type = "A", lbs_map_key = "private" },
        # ]
      }
    }
    baseline_acm_certificates = {
      planetfm_wildcard_cert = {
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.planetfm.service.justice.gov.uk",
          "cafmwebx.az.justice.gov.uk",
          "cafmwebx2.az.justice.gov.uk",
          "cafmtx.az.justice.gov.uk",
          "cafmtrainweb.az.justice.gov.uk",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "wildcard cert for planetfm ${local.environment} domains"
        }
      }
    }
  }
}
