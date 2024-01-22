# nomis-production environment settings
locals {

  # baseline config
  production_config = {

    baseline_ec2_instances = {
      # database servers
      pd-cafm-db-a = merge(local.defaults_database_ec2, {
        config = merge(local.defaults_database_ec2.config, {
          ami_name          = "pd-cafm-db-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_database_ec2.instance, {
          instance_type = "r6i.4xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 500 }
          "/dev/sdc"  = { type = "gp3", size = 50 }
          "/dev/sdd"  = { type = "gp3", size = 224 }
          "/dev/sde"  = { type = "gp3", size = 500 }
          "/dev/sdf"  = { type = "gp3", size = 100 }
          "/dev/sdg"  = { type = "gp3", size = 85 }
        }
        tags = merge(local.defaults_database_ec2.tags, {
          description       = "Copy of PDFDW0030 SQL Server"
          app-config-status = "pending"
          ami               = "pd-cafm-db-a"
        })
      })
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

      # app servers 
      pd-cafm-a-10-b = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-cafm-a-10-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "t3.xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 200 }
        }
        tags = {
          description       = "RDS Session Host and CAFM App Server/PFME Licence Server copy of PDFAW0010"
          app-config-status = "pending"
          os-type           = "Windows"
          ami               = "pd-cafm-a-10-b"
          component         = "app"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })
      pd-cafm-a-11-a = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-cafm-a-11-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "t3.xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 200 }
        }
        tags = {
          description       = "CAFM App server copy of PDFWA0011"
          app-config-status = "pending"
          os-type           = "Windows"
          ami               = "pd-cafm-a-11-a"
          component         = "app"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })
      pd-cafm-a-12-b = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-cafm-a-12-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "t3.xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 200 }
        }
        tags = {
          description       = "RDS Session Host and CAFM App Server. Copy of PDFAW0012"
          app-config-status = "pending"
          os-type           = "Windows"
          ami               = "pd-cafm-a-12-b"
          component         = "app"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })
      pd-cafm-a-13-a = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-cafm-a-13-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "t3.xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 28 }
        }
        tags = {
          description       = "RDS Session Host and CAFM App Server. Copy of PDFAW0013"
          app-config-status = "pending"
          os-type           = "Windows"
          ami               = "pd-cafm-a-13-a"
          component         = "app"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })
      pd-cafm-a-14-b = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-cafm-a-14-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "t3.xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 200 }
        }
        tags = {
          description       = "RDS Session Host and CAFM App Server copy of PDFAW0014"
          app-config-status = "pending"
          os-type           = "Windows"
          ami               = "pd-cafm-a-14-b"
          component         = "app"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })
      pd-cafm-a-15-a = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-cafm-a-15-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "t3.large"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 100 }
        }
        tags = {
          description       = "RDS Session Broker / RDS Licence Server. Copy of PDFAW0015"
          app-config-status = "pending"
          os-type           = "Windows"
          ami               = "pd-cafm-a-15-a"
          component         = "app"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      # web servers
      pd-cafm-w-5-a = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pd-cafm-w-5-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "t3.large"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 100 }
        }
        tags = {
          description       = "CAFM Web Portal Server. Copy of PDFWW0005"
          app-config-status = "pending"
          os-type           = "Windows"
          ami               = "pd-cafm-w-5-a"
          component         = "web"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })
      pd-cafm-w-6-b = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pd-cafm-w-6-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "t3.large"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 100 }
        }
        tags = {
          description       = "CAFM Web Portal Server copy of PDFWW0006"
          app-config-status = "pending"
          os-type           = "Windows"
          ami               = "pd-cafm-w-6-b"
          component         = "web"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })
      pd-cafm-w-36-b = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pd-cafm-w-36-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "t3.xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 28 }
        }
        tags = {
          description       = "CAFM Asset Management. Copy of PDFWW00036"
          app-config-status = "pending"
          os-type           = "Windows"
          ami               = "pd-cafm-w-36-b"
          component         = "web"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })
      pd-cafm-w-37-a = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pd-cafm-w-37-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "t3.xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 28 }
        }
        tags = {
          description       = "CAFM Assessment Management copy of PFWW00037"
          app-config-status = "pending"
          os-type           = "Windows"
          ami               = "pd-cafm-w-37-a"
          component         = "web"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })
      pd-cafm-w-38-b = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pd-cafm-w-38-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_web_ec2.instance, {
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
    baseline_lbs = {
      private = {
        internal_lb                      = true
        enable_delete_protection         = false
        load_balancer_type               = "application"
        idle_timeout                     = 3600
        security_groups                  = ["loadbalancer"]
        subnets                          = module.environment.subnets["private"].ids
        enable_cross_zone_load_balancing = true

        instance_target_groups = {
          web-56-80 = {
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
              { ec2_instance_name = "pd-cafm-w-5-a" },
              { ec2_instance_name = "pd-cafm-w-6-b" },
            ]
          }
          web-3637-80 = {
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
              { ec2_instance_name = "pd-cafm-w-36-b" },
              { ec2_instance_name = "pd-cafm-w-37-a" },
            ]
          }
          web-38-80 = {
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
              { ec2_instance_name = "pd-cafm-w-38-b" },
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
              web-56-80 = {
                priority = 5680
                actions = [{
                  type              = "forward"
                  target_group_name = "web-56-80"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "cafmwebx.planetfm.service.justice.gov.uk",
                      "cafmwebx.az.justice.gov.uk",
                    ]
                  }
                }]
              }
              web-3637-80 = {
                priority = 3637
                actions = [{
                  type              = "forward"
                  target_group_name = "web-3637-80"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "cafmwebx2.planetfm.service.justice.gov.uk",
                      "cafmwebx2.az.justice.gov.uk",
                    ]
                  }
                }]
              }
              web-38-80 = {
                priority = 3880
                actions = [{
                  type              = "forward"
                  target_group_name = "web-38-80"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "cafmtrainweb.planetfm.service.justice.gov.uk",
                      "cafmtrainweb.az.justice.gov.uk",
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
