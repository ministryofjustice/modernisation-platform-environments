# nomis-preproduction environment settings
locals {

  # baseline config
  preproduction_config = {
    baseline_ec2_instances = {
      # database server
      pp-cafm-db-a = merge(local.defaults_database_ec2, {
        config = merge(local.defaults_database_ec2.config, {
          ami_name          = "pp-cafm-db-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_database_ec2.instance, {
          instance_type = "r6i.xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 250 }
          "/dev/sdc"  = { type = "gp3", size = 50 }
          "/dev/sdd"  = { type = "gp3", size = 250 }
          "/dev/sde"  = { type = "gp3", size = 50 }
          "/dev/sdf"  = { type = "gp3", size = 250 }
          "/dev/sdg"  = { type = "gp3", size = 200 }
        }
        cloudwatch_metric_alarms = {} # TODO: remove this later when @Dominic has added finished changing the alarms
        tags = merge(local.defaults_database_ec2.tags, {
          description       = "copy of PPFDW0030 SQL Server"
          app-config-status = "pending"
          ami               = "pp-cafm-db-a"
        })
      })

      # app servers
      pp-cafm-a-10-b = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pp-cafm-a-10-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "t3.large"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          
        }
        cloudwatch_metric_alarms = {} # TODO: remove this later when @Dominic has added finished changing the alarms
        tags = merge(local.defaults_app_ec2.tags, {
          description       = "Migrated server PPFAW0010 PFME Licence Server"
          ami               = "pp-cafm-a-10-b"
          app-config-status = "pending"
        })
      })

      pp-cafm-a-11-a = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pp-cafm-a-11-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "t3.large"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          
        }
        cloudwatch_metric_alarms = {} # TODO: remove this later when @Dominic has added finished changing the alarms
        tags = merge(local.defaults_app_ec2.tags, {
          description       = "Migrated server PPFAW011 RDS session host app server"
          ami               = "pp-cafm-a-11-a"
          app-config-status = "pending"
        })
      })


      # web servers
      pp-cafm-w-2-b = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pp-cafm-w-2-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "t3.large"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 100 }
        }
        cloudwatch_metric_alarms = {} # TODO: remove this later when @Dominic has added finished changing the alarms
        tags = merge(local.defaults_web_ec2.tags, {
          description       = "Migrated server PPFWW0002 Web Access Server / RDS Gateway Server"
          ami               = "pp-cafm-w-2-b"
          app-config-status = "pending"
        })
      })

      pp-cafm-w-3-a = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pp-cafm-w-2-b"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "t3.large"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 100 }
        }
        cloudwatch_metric_alarms = {} # TODO: remove this later when @Dominic has added finished changing the alarms
        tags = merge(local.defaults_web_ec2.tags, {
          description       = "Migrated server PPFWW0003 Web Access Server / RDS Gateway Server"
          ami               = "pp-cafm-w-2-b"
          app-config-status = "pending"
        })
      })

      pp-cafm-w-4-b = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pp-cafm-w-4-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "t3.large"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          
        }
        cloudwatch_metric_alarms = {} # TODO: remove this later when @Dominic has added finished changing the alarms
        tags = merge(local.defaults_web_ec2.tags, {
          description       = "Migrated server PPFWW0004 Web Portal Server"
          ami               = "pp-cafm-w-4-b"
          app-config-status = "pending"
        })
      })

      pp-cafm-w-5-a = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pp-cafm-w-5-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "t3.large"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
         
        }
        cloudwatch_metric_alarms = {} # TODO: remove this later when @Dominic has added finished changing the alarms
        tags = merge(local.defaults_web_ec2.tags, {
          description       = "Migrated server PPFWW0005 Web Portal Server"
          ami               = "pp-cafm-w-5-a"
          app-config-status = "pending"
        })
      })
    }
    baseline_lbs = {
      private = {
        internal_lb                      = true
        enable_delete_protection         = false
        loadbalancer_type                = "application"
        idle_timeout                     = 3600
        security_groups                  = ["loadbalancer"]
        subnets                          = module.environment.subnets["private"].ids
        enable_cross_zone_load_balancing = true

        instance_target_groups = {
          web-23-80 = {
            port     = 80
            protocol = "HTTP"
            health_check = {
              enabled             = true
              path                = "/RDWeb"
              healthy_threshold   = 3
              unhealthy_threshold = 5
              timeout             = 5
              interval            = 30
              matcher             = "200-399"
              port                = 80
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
            attachments = [
              { ec2_instance_name = "pp-cafm-w-2-b" },
              { ec2_instance_name = "pp-cafm-w-3-a" },
            ]
          }
          web-45-80 = {
            port     = 80
            protocol = "HTTP"
            health_check = {
              enabled             = true
              path                = "/"
              healthy_threshold   = 3
              unhealthy_threshold = 5
              timeout             = 5
              interval            = 30
              matcher             = "200-399"
              port                = 80
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
            attachments = [
              { ec2_instance_name = "pp-cafm-w-4-b" },
              { ec2_instance_name = "pp-cafm-w-5-a" },
            ]
          }
        }
        listeners = {
          http = {
            port     = 80
            protocol = "HTTP"
            default_action = {
              type = "redirect"
              redirect = {
                port        = 443
                protocol    = "HTTPS"
                status_code = "HTTP_301"
              }
            }
          }
          https = {
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-2016-08"
            certificate_names_or_arns = ["planetfm_wildcard_cert"]
            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "Not implemented"
                status_code  = "501"
              }
            }
            rules = {
              web-23-80 = {
                priority = 2380
                actions = [{
                  type              = "forward"
                  target_group_name = "web-23-80"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "cafmtx.pp.planetfm.service.justice.gov.uk",
                      "pp-cafmtx.az.justice.gov.uk",
                    ]
                  }
                }]
              }
              web-45-80 = {
                priority = 4580
                actions = [{
                  type              = "forward"
                  target_group_name = "web-45-80"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "cafmwebx.pp.planetfm.service.justice.gov.uk",
                      "pp-cafmwebx.az.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          }
        }
      }
    }
    baseline_route53_zones = {
      "pp.planetfm.service.justice.gov.uk" = {
        records = [
          # set to PPFDW0030 PP SQL server for planetfm, not applied as not used previously in testing
          # { name = "ppplanet", type = "A", ttl = "300", records = ["10.40.50.132"] },
          # { name = "ppplanet-a", type = "A", ttl = "300", records = ["10.40.42.132"] },
          # { name = "ppplanet-b", type = "CNAME", ttl = "300", records = ["pp-cafm-db-a.planetfm.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
        ]
        lb_alias_records = [
          { name = "cafmtx", type = "A", lbs_map_key = "private" },
          { name = "cafmwebx", type = "A", lbs_map_key = "private" },
        ]
      }
    }
    baseline_acm_certificates = {
      planetfm_wildcard_cert = {

        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.pp.planetfm.service.justice.gov.uk",
          "pp-cafmwebx.az.justice.gov.uk",
          "pp-cafmtx.az.justice.gov.uk",
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
