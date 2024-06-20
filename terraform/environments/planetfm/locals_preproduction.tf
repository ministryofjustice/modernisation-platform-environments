locals {

  baseline_presets_preproduction = {
    options = {}
  }

  # please keep resources in alphabetical order
  baseline_preproduction = {

    acm_certificates = {
      planetfm_wildcard_cert = {
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "modernisation-platform.service.justice.gov.uk"
        external_validation_records_created = true
        subject_alternate_names = [
          "*.pp.planetfm.service.justice.gov.uk",
          "pp-cafmwebx.az.justice.gov.uk",
          "pp-cafmtx.az.justice.gov.uk",
        ]
        tags = {
          description = "wildcard cert for planetfm preproduction domains"
        }
      }
    }

    ec2_instances = {
      # app servers
      pp-cafm-a-10-b = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pp-cafm-a-10-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
        }
        instance = merge(local.defaults_app_ec2.instance, {
          disable_api_stop        = true
          disable_api_termination = true
          instance_type           = "t3.large"
          monitoring              = true
        })
        tags = merge(local.defaults_app_ec2.tags, {
          ami           = "pp-cafm-a-10-b"
          description   = "RDS Session Host and CAFM App Server/PFME Licence Server"
          pre-migration = "PPFAW0010"
        })
      })

      pp-cafm-a-11-a = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pp-cafm-a-11-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
        }
        instance = merge(local.defaults_app_ec2.instance, {
          disable_api_stop        = true
          disable_api_termination = true
          instance_type           = "t3.large"
          monitoring              = true
        })
        tags = merge(local.defaults_app_ec2.tags, {
          ami           = "pp-cafm-a-11-a"
          description   = "RDS session host and app server"
          pre-migration = "PPFAW011"
        })
      })

      # database servers
      pp-cafm-db-a = merge(local.defaults_database_ec2, {
        config = merge(local.defaults_database_ec2.config, {
          ami_name          = "pp-cafm-db-a"
          availability_zone = "eu-west-2a"
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
        instance = merge(local.defaults_database_ec2.instance, {
          disable_api_stop        = true
          disable_api_termination = true
          instance_type           = "r6i.xlarge"
          monitoring              = true
        })
        tags = merge(local.defaults_database_ec2.tags, {
          app-config-status = "pending"
          ami               = "pp-cafm-db-a"
          description       = "SQL Server"
          pre-migration     = "PPFDW0030"
        })
      })

      # web servers
      pp-cafm-w-4-b = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pp-cafm-w-4-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
        }
        instance = merge(local.defaults_web_ec2.instance, {
          disable_api_stop        = true
          disable_api_termination = true
          instance_type           = "t3.large"
          monitoring              = true
        })
        tags = merge(local.defaults_web_ec2.tags, {
          ami           = "pp-cafm-w-4-b"
          description   = "Web Portal Server"
          pre-migration = "PPFWW0004"
        })
      })

      pp-cafm-w-5-a = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pp-cafm-w-5-a"
          availability_zone = "eu-west-2a"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          disable_api_stop        = true
          disable_api_termination = true
          instance_type           = "t3.large"
          monitoring              = true
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
        }
        tags = merge(local.defaults_web_ec2.tags, {
          ami           = "pp-cafm-w-5-a"
          description   = "Migrated server PPFWW0005 Web Portal Server"
          pre-migration = "PPFWW0005"
        })
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
          web-45-80 = {
            attachments = [
              { ec2_instance_name = "pp-cafm-w-4-b" },
              { ec2_instance_name = "pp-cafm-w-5-a" },
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

    route53_zones = {
      "pp.planetfm.service.justice.gov.uk" = {
        records = [
          { name = "_658adffab7a58a4d5a86804a2b6eb2f7", type = "CNAME", ttl = 86400, records = ["_c649cb794d2fa2e1ac4d3f6fb4e1c8a7.mhbtsbpdnt.acm-validations.aws"] },
          { name = "cafmtx", type = "CNAME", ttl = 3600, records = ["rdweb1.preproduction.hmpps-domain.service.justice.gov.uk"] },
        ]
        lb_alias_records = [
          { name = "cafmwebx", type = "A", lbs_map_key = "private" },
        ]
      }
    }

    security_groups = {
      cafm_app_fixngo = {
        description = "Allow fixngo cafm app connectivity"
        ingress = {
          all-from-self = {
            description = "Allow all ingress to self"
            from_port   = 0
            to_port     = 0
            protocol    = -1
            self        = true
          }
          smb_udp_cafm_app_fixngo = {
            description = "445: UDP SMB ingress from Cafm App Fixngo"
            from_port   = 445
            to_port     = 445
            protocol    = "UDP"
            cidr_blocks = ["10.40.50.64/26"] #  production    = ["10.40.15.64/26"]
          }
          rdp_tcp_cafm_app_fixngo = {
            description = "3389: Allow RDP UDP ingress from Cafm App Fixngo"
            from_port   = 3389
            to_port     = 3389
            protocol    = "TCP"
            cidr_blocks = ["10.40.50.64/26"]
          }
          rdp_udp_cafm_app_fixngo = {
            description = "3389: Allow RDP UDP ingress from Cafm App Fixngo"
            from_port   = 3389
            to_port     = 3389
            protocol    = "UDP"
            cidr_blocks = ["10.40.50.64/26"]
          }
          winrm_tcp_cafm_app_fixngo = {
            description = "5985: TCP WinRM ingress from Cafm App Fixngo"
            from_port   = 5985
            to_port     = 5986
            protocol    = "TCP"
            cidr_blocks = ["10.40.50.64/26"]
          }
          rpc_dynamic_udp_cafm_app_fixngo = {
            description = "49152-65535: UDP Dynamic Port rang from Cafm App Fixngo"
            from_port   = 49152
            to_port     = 65535
            protocol    = "UDP"
            cidr_blocks = ["10.40.50.64/26"]
          }
          rpc_dynamic_tcp_cafm_app_fixngo = {
            description = "49152-65535: TCP Dynamic Port range from Cafm App Fixngo"
            from_port   = 49152
            to_port     = 65535
            protocol    = "TCP"
            cidr_blocks = ["10.40.50.64/26"]
          }
        }
        egress = {
          all = {
            description = "Allow all traffic outbound"
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
        }
      }
    }
  }
}
