locals {

  baseline_presets_production = {
    options = {}
  }

  # please keep resources in alphabetical order
  baseline_production = {

    acm_certificates = {
      planetfm_wildcard_cert = {
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "modernisation-platform.service.justice.gov.uk"
        external_validation_records_created = true
        subject_alternate_names = [
          "*.planetfm.service.justice.gov.uk",
          "cafmwebx.az.justice.gov.uk",
          "cafmwebx2.az.justice.gov.uk",
          "cafmtx.az.justice.gov.uk",
          "cafmtrainweb.az.justice.gov.uk",
        ]
        tags = {
          description = "wildcard cert for planetfm production domains"
        }
      }
    }

    ec2_instances = {
      # app servers 
      pd-cafm-a-10-b = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-cafm-a-10-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 200 }
        }
        instance = merge(local.defaults_app_ec2.instance, {
          disable_api_stop        = true
          disable_api_termination = true
          instance_type           = "t3.xlarge"
          monitoring              = true
        })
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
        tags = {
          ami           = "pd-cafm-a-10-b"
          description   = "RDS Session Host and CAFM App Server/PFME Licence Server"
          pre-migration = "PDFAW0010"
        }
      })

      pd-cafm-a-11-a = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-cafm-a-11-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 200 }
        }
        instance = merge(local.defaults_app_ec2.instance, {
          disable_api_stop        = true
          disable_api_termination = true
          instance_type           = "t3.xlarge"
          monitoring              = true
        })
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
        tags = {
          pre-migration = "PDFWA0011"
          description   = "RDS session host and app server"
          ami           = "pd-cafm-a-11-a"
        }
      })

      pd-cafm-a-12-b = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-cafm-a-12-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 200 }
        }
        instance = merge(local.defaults_app_ec2.instance, {
          disable_api_stop        = true
          disable_api_termination = true
          instance_type           = "t3.xlarge"
          monitoring              = true
        })
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
        tags = {
          ami           = "pd-cafm-a-12-b"
          description   = "RDS session host and app Server"
          pre-migration = "PDFAW0012"
        }
      })

      pd-cafm-a-13-a = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-cafm-a-13-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 28 }
        }
        instance = merge(local.defaults_app_ec2.instance, {
          disable_api_stop        = true
          disable_api_termination = true
          instance_type           = "t3.xlarge"
          monitoring              = true
        })
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
        tags = {
          ami           = "pd-cafm-a-13-a"
          description   = "RDS session host and App Server"
          pre-migration = "PDFAW0013"
        }
      })

      # database servers
      pd-cafm-db-a = merge(local.defaults_database_ec2, {
        config = merge(local.defaults_database_ec2.config, {
          ami_name          = "pd-cafm-db-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 500 }
          "/dev/sdc"  = { type = "gp3", size = 50 }
          "/dev/sdd"  = { type = "gp3", size = 224 }
          "/dev/sde"  = { type = "gp3", size = 500 }
          "/dev/sdf"  = { type = "gp3", size = 100 }
          "/dev/sdg"  = { type = "gp3", size = 85 }
          "/dev/sdh"  = { type = "gp3", size = 150 } # T: drive
          "/dev/sdi"  = { type = "gp3", size = 250 } # U: drive
        }
        instance = merge(local.defaults_database_ec2.instance, {
          disable_api_stop        = true
          disable_api_termination = true
          instance_type           = "r6i.4xlarge"
          monitoring              = true
        })
        tags = merge(local.defaults_database_ec2.tags, {
          app-config-status = "pending"
          ami               = "pd-cafm-db-a"
          description       = "SQL Server"
          pre-migration     = "PDFDW0030"
        })
      })

      pd-cafm-db-b = merge(local.defaults_database_ec2, {
        config = merge(local.defaults_database_ec2.config, {
          ami_name          = "pd-cafm-db-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 500 }
          "/dev/sdc"  = { type = "gp3", size = 112 }
          "/dev/sdd"  = { type = "gp3", size = 500 }
          "/dev/sde"  = { type = "gp3", size = 50 }
          "/dev/sdf"  = { type = "gp3", size = 85 }
          "/dev/sdg"  = { type = "gp3", size = 100 }
          "/dev/sdh"  = { type = "gp3", size = 150 } # T: drive
          "/dev/sdi"  = { type = "gp3", size = 250 } # U: drive
        }
        instance = merge(local.defaults_database_ec2.instance, {
          disable_api_stop        = true
          disable_api_termination = true
          instance_type           = "r6i.4xlarge"
          monitoring              = true
        })
        tags = merge(local.defaults_database_ec2.tags, {
          app-config-status = "pending"
          ami               = "pd-cafm-db-b"
          description       = "SQL resilient Server"
          pre-migration     = "PDFDW0031"
        })
      })

      # web servers
      pd-cafm-w-36-b = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pd-cafm-w-36-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 28 }
        }
        instance = merge(local.defaults_web_ec2.instance, {
          disable_api_stop        = true
          disable_api_termination = true
          instance_type           = "t3.xlarge"
          monitoring              = true
        })
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
        tags = {
          ami           = "pd-cafm-w-36-b"
          description   = "CAFM Asset Management"
          pre-migration = "PDFWW00036"
        }
      })

      pd-cafm-w-37-a = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pd-cafm-w-37-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 28 }
        }
        instance = merge(local.defaults_web_ec2.instance, {
          disable_api_stop        = true
          disable_api_termination = true
          instance_type           = "t3.xlarge"
          monitoring              = true
        })
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
        tags = {
          pre-migration = "PFWW00037"
          description   = "CAFM Assessment Management"
          ami           = "pd-cafm-w-37-a"
        }
      })

      pd-cafm-w-38-b = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pd-cafm-w-38-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 100 }
        }
        instance = merge(local.defaults_web_ec2.instance, {
          disable_api_stop        = true
          disable_api_termination = true
          instance_type           = "t3.large"
          monitoring              = true
        })
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
        tags = {
          ami           = "pd-cafm-w-38-b"
          description   = "CAFM Web Training"
          pre-migration = "PDFWW3QCP660001"
        }
      })
    }

    lbs = {
      private = {
        enable_cross_zone_load_balancing = true
        enable_delete_protection         = false
        idle_timeout                     = 3600
        internal_lb                      = true
        load_balancer_type               = "application"
        security_groups                  = ["loadbalancer"]
        subnets                          = module.environment.subnets["private"].ids

        instance_target_groups = {
          web-3637-80 = {
            attachments = [
              { ec2_instance_name = "pd-cafm-w-36-b" },
              { ec2_instance_name = "pd-cafm-w-37-a" },
            ]
            health_check = {
              enabled             = true
              healthy_threshold   = 3
              interval            = 30
              matcher             = "200-399"
              path                = "/"
              port                = 80
              timeout             = 5
              unhealthy_threshold = 5
            }
            port     = 80
            protocol = "HTTP"
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
          }
          web-38-80 = {
            attachments = [
              { ec2_instance_name = "pd-cafm-w-38-b" },
            ]
            health_check = {
              enabled             = true
              healthy_threshold   = 3
              interval            = 30
              matcher             = "200-399"
              path                = "/"
              port                = 80
              timeout             = 5
              unhealthy_threshold = 5
            }
            port     = 80
            protocol = "HTTP"
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
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
            certificate_names_or_arns = ["planetfm_wildcard_cert"]
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-TLS13-1-2-2021-06"

            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "Not implemented"
                status_code  = "501"
              }
            }

            rules = {
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

    route53_zones = {
      "planetfm.service.justice.gov.uk" = {
        records = [
          { name = "_a6a2b9e651b91ed3f1e906b4f1c3c317", type = "CNAME", ttl = 86400, records = ["_c4257165635a7b495df6c4fbd986c09f.mhbtsbpdnt.acm-validations.aws"] },
          { name = "cafmtx", type = "CNAME", ttl = 3600, records = ["rdweb1.hmpps-domain.service.justice.gov.uk"] },
          { name = "pp", type = "NS", ttl = "86400", records = ["ns-1407.awsdns-47.org", "ns-1645.awsdns-13.co.uk", "ns-63.awsdns-07.com", "ns-730.awsdns-27.net"] },
          { name = "test", type = "NS", ttl = "86400", records = ["ns-1128.awsdns-13.org", "ns-2027.awsdns-61.co.uk", "ns-854.awsdns-42.net", "ns-90.awsdns-11.com"] },
        ]
        lb_alias_records = [
          { name = "cafmtrainweb", type = "A", lbs_map_key = "private" },
          { name = "cafmwebx2", type = "A", lbs_map_key = "private" },
        ]
      }
    }
  }
}
