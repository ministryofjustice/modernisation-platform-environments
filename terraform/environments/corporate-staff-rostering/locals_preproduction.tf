# nomis-preproduction environment settings
locals {

  # baseline config
  preproduction_config = {

    baseline_ssm_parameters = {
      "/oracle/database/PPIWFM" = local.database_ssm_parameters
    }

    baseline_ec2_instances = {
      pp-csr-db-a = merge(local.database_ec2, {
        config = merge(local.database_ec2.config, {
          ami_name          = "hmpps_ol_8_5_oracledb_19c_release_2023-07-14T15-36-30.795Z"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.database_ec2.instance, {
          instance_type                = "r6i.xlarge"
          metadata_options_http_tokens = "optional" # the Oracle installer cannot accommodate a token
        })

        ebs_volumes = merge(local.database_ec2.ebs_volumes, {
          "/dev/sda1" = { label = "root", size = 30 }
          "/dev/sdb"  = { label = "app", size = 100 } # /u01
          "/dev/sdc"  = { label = "app", size = 100 } # /u02
        })

        ebs_volume_config = merge(local.database_ec2.ebs_volume_config, {
          data = {
            iops       = 3000
            throughput = 125
            total_size = 1000
          }
          flash = {
            iops       = 3000
            throughput = 125
            total_size = 100
          }
        })

        ssm_parameters = {
          asm-passwords = {}
        }

        tags = {
          description = "PP CSR DB server"
          ami         = "base_ol_8_5"
          os-type     = "Linux"
          component   = "test"
          server-type = "csr-db"
        }
      })

      pp-csr-a-17-a = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "pp-csr-a-17-a"
          ami_owner                     = "self"
          availability_zone             = "${local.region}a"
          ebs_volumes_copy_all_from_ami = false
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type           = "m5.2xlarge"
          disable_api_termination = true
          monitoring              = true
          vpc_security_group_ids  = ["domain", "app", "jumpserver"]
          tags = {
            backup-plan         = "daily-and-weekly"
            instance-scheduling = "skip-scheduling"
          }
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 56 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        tags = {
          description = "copy of PPCAW00017 for csr ${local.environment}"
          os-type     = "Windows"
          ami         = "pp-csr-a-17-a"
          component   = "app"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      }

      pp-csr-w-7-b = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "pp-csr-w-7-b"
          ami_owner                     = "self"
          availability_zone             = "${local.region}b"
          ebs_volumes_copy_all_from_ami = false
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type           = "m5.2xlarge"
          disable_api_termination = true
          monitoring              = true
          vpc_security_group_ids  = ["migration-web-sg", "domain-controller"]
          tags = {
            backup-plan         = "daily-and-weekly"
            instance-scheduling = "skip-scheduling"
          }
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 56 }
        }
        tags = {
          description = "copy of PPCWW00007 for csr ${local.environment}"
          os-type     = "Windows"
          ami         = "pp-csr-w-7-b"
          component   = "web"
        }
      }

      pp-csr-w-8-b = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "pp-csr-w-8-b"
          ami_owner                     = "self"
          availability_zone             = "${local.region}b"
          ebs_volumes_copy_all_from_ami = false
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type           = "m5.2xlarge"
          disable_api_termination = true
          monitoring              = true
          vpc_security_group_ids  = ["migration-web-sg", "domain-controller"]
          tags = {
            backup-plan         = "daily-and-weekly"
            instance-scheduling = "skip-scheduling"
          }
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 200 }
          "/dev/sdb"  = { type = "gp3", size = 56 }
        }
        tags = {
          description = "copy of PPCWW00008 for csr ${local.environment}"
          os-type     = "Windows"
          ami         = "pp-csr-w-8-b"
          component   = "web"
        }
      }

      pp-csr-w-1-b = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "PPCWW00001"
          ami_owner                     = "self"
          availability_zone             = "${local.region}b"
          ebs_volumes_copy_all_from_ami = false
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type           = "m5.2xlarge"
          disable_api_termination = true
          monitoring              = true
          vpc_security_group_ids  = ["migration-web-sg", "domain-controller"]
          tags = {
            backup-plan         = "daily-and-weekly"
            instance-scheduling = "skip-scheduling"
          }
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 56 }
          "/dev/sdc"  = { type = "gp3", size = 129 }
          "/dev/sdd"  = { type = "gp3", size = 129 }
        }
        tags = {
          description = "copy of PPCWW00001 for csr ${local.environment}"
          os-type     = "Windows"
          ami         = "PPCWW00001"
          component   = "web"
        }
      }

      pp-csr-w-5-a = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "PPCWW00005"
          ami_owner                     = "self"
          availability_zone             = "${local.region}a"
          ebs_volumes_copy_all_from_ami = false
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type           = "m5.2xlarge"
          disable_api_termination = true
          monitoring              = true
          vpc_security_group_ids  = ["domain", "web", "jumpserver"]
          tags = {
            backup-plan         = "daily-and-weekly"
            instance-scheduling = "skip-scheduling"
          }
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 56 }
          "/dev/sdc"  = { type = "gp3", size = 129 }
        }
        tags = {
          description = "copy of PPCWW00005 for csr ${local.environment}"
          os-type     = "Windows"
          ami         = "PPCWW00005"
          component   = "web"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      }
      pp-csr-a-14-b = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "pp-csr-a-14-b"
          ami_owner                     = "self"
          availability_zone             = "${local.region}b"
          ebs_volumes_copy_all_from_ami = false
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type           = "m5.2xlarge"
          disable_api_termination = true
          monitoring              = true
          vpc_security_group_ids  = ["domain", "app", "jumpserver"]
          tags = {
            backup-plan         = "daily-and-weekly"
            instance-scheduling = "skip-scheduling"
          }
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 56 }
        }
        tags = {
          description = "copy of PPCAW00014 for csr ${local.environment}"
          os-type     = "Windows"
          ami         = "pp-csr-a-14-b"
          component   = "app"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      }
      pp-csr-w-2-b = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "pp-csr-w-2-b"
          ami_owner                     = "self"
          availability_zone             = "${local.region}b"
          ebs_volumes_copy_all_from_ami = false
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type           = "m5.2xlarge"
          disable_api_termination = true
          monitoring              = true
          vpc_security_group_ids  = ["domain", "web", "jumpserver"]
          tags = {
            backup-plan         = "daily-and-weekly"
            instance-scheduling = "skip-scheduling"
          }
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 129 }
          "/dev/sdc"  = { type = "gp3", size = 56 }
          "/dev/sdd"  = { type = "gp3", size = 129 }
        }
        tags = {
          description = "copy of pp-csr-w-2-b for csr ${local.environment}"
          os-type     = "Windows"
          ami         = "pp-csr-w-2-b"
          component   = "web"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      }
    }

    baseline_ec2_autoscaling_groups = {
      pp-web-tst-1 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2023-*" # Microsoft Windows Server 2022 Base
          ami_owner                     = "754260907303"
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = base64encode(file("./templates/test-user-data.yaml"))
          instance_profile_policies     = concat(module.baseline_presets.ec2_instance.config.default.instance_profile_policies, ["CSRWebServerPolicy"])
        })

        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["web", "domain", "jumpserver"]
          instance_type          = "t3.medium"

        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 256 }
        }
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0 # set to 0 while testing
        })
        tags = {
          description = "Test Windows Web Server 2019"
          os-type     = "Windows"
          component   = "Test"
          server-type = "test-windows-server"
        }
      }
    }

    baseline_lbs = {
      private = {
        internal_lb              = true
        enable_delete_protection = false
        force_destroy_bucket     = true
        idle_timeout             = 3600
        public_subnets           = module.environment.subnets["private"].ids
        security_groups          = ["load-balancer"]

        instance_target_groups = {
          web-12-7770 = {
            port     = 7770
            protocol = "HTTP"
            health_check = {
              enabled             = true
              interval            = 30
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 7770
              timeout             = 5
              unhealthy_threshold = 5
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
            attachments = [
              { ec2_instance_name = "pp-csr-w-2-b" },
            ]
          }
          web-56-7770 = {
            port     = 7770
            protocol = "HTTP"
            health_check = {
              enabled             = true
              interval            = 30
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 7770
              timeout             = 5
              unhealthy_threshold = 5
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
            attachments = [
              { ec2_instance_name = "pp-csr-w-5-a" },
            ]
          }
          web-12-7771 = {
            port     = 7771
            protocol = "HTTP"
            health_check = {
              enabled             = true
              interval            = 30
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 7771
              timeout             = 5
              unhealthy_threshold = 5
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
            attachments = [
              { ec2_instance_name = "pp-csr-w-2-b" },
            ]
          }
          web-56-7771 = {
            port     = 7771
            protocol = "HTTP"
            health_check = {
              enabled             = true
              interval            = 30
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 7771
              timeout             = 5
              unhealthy_threshold = 5
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
            attachments = [
              { ec2_instance_name = "pp-csr-w-5-a" },
            ]
          }
          web-12-7780 = {
            port     = 7780
            protocol = "HTTP"
            health_check = {
              enabled             = true
              interval            = 30
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 7780
              timeout             = 5
              unhealthy_threshold = 5
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
            attachments = [
              { ec2_instance_name = "pp-csr-w-2-b" },
            ]
          }
          web-56-7780 = {
            port     = 7780
            protocol = "HTTP"
            health_check = {
              enabled             = true
              interval            = 30
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 7780
              timeout             = 5
              unhealthy_threshold = 5
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
            attachments = [
              { ec2_instance_name = "pp-csr-w-5-a" },
            ]
          }
          web-12-7781 = {
            port     = 7781
            protocol = "HTTP"
            health_check = {
              enabled             = true
              interval            = 30
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 7781
              timeout             = 5
              unhealthy_threshold = 5
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
            attachments = [
              { ec2_instance_name = "pp-csr-w-2-b" },
            ]
          }
          web-56-7781 = {
            port     = 7781
            protocol = "HTTP"
            health_check = {
              enabled             = true
              interval            = 30
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 7781
              timeout             = 5
              unhealthy_threshold = 5
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
            attachments = [
              { ec2_instance_name = "pp-csr-w-5-a" },
            ]
          }
        }

        listeners = {
          http-80 = {
            alarm_target_group_names = []
            port                     = 80
            protocol                 = "HTTP"

            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "Not implemented"
                status_code  = "501"
              }
            }

            rules = {
              web-12-7770 = {
                priority = 1270
                actions = [{
                  type              = "forward"
                  target_group_name = "web-12-7770"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "r1.pp.csr.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              web-56-7770 = {
                priority = 5670
                actions = [{
                  type              = "forward"
                  target_group_name = "web-56-7770"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "r3.pp.csr.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              web-12-7771 = {
                priority = 1271
                actions = [{
                  type              = "forward"
                  target_group_name = "web-12-7771"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "r2.pp.csr.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              web-56-7771 = {
                priority = 5671
                actions = [{
                  type              = "forward"
                  target_group_name = "web-56-7771"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "r4.pp.csr.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          }
          http-7780 = {
            alarm_target_group_names = []
            port                     = 7780
            protocol                 = "HTTP"

            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "Not implemented"
                status_code  = "501"
              }
            }

            rules = {
              web-12-7780 = {
                priority = 1280
                actions = [{
                  type              = "forward"
                  target_group_name = "web-12-7780"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "r1.pp.csr.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              web-56-7780 = {
                priority = 5680
                actions = [{
                  type              = "forward"
                  target_group_name = "web-56-7780"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "r3.pp.csr.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          }
          http-7781 = {
            alarm_target_group_names = []
            port                     = 7781
            protocol                 = "HTTP"

            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "Not implemented"
                status_code  = "501"
              }
            }

            rules = {
              web-12-7781 = {
                priority = 1281
                actions = [{
                  type              = "forward"
                  target_group_name = "web-12-7781"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "r2.pp.csr.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              web-56-7781 = {
                priority = 5681
                actions = [{
                  type              = "forward"
                  target_group_name = "web-56-7781"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "r4.pp.csr.service.justice.gov.uk",
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
      "pp.csr.service.justice.gov.uk" = {
        records = [
          # Set to IP of the Azure CSR PP DB in PPCDL00019
          { name = "ppiwfm", type = "A", ttl = "300", records = ["10.40.42.132"] },
          { name = "ppiwfm-a", type = "A", ttl = "300", records = ["10.40.42.132"] },
          { name = "ppiwfm-b", type = "CNAME", ttl = "300", records = ["pp-csr-db-a.corporate-staff-rostering.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          # { name = "r3", type = "CNAME", ttl = "300", records = ["pp-csr-w-5-a.corporate-staff-rostering.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
        ]
        lb_alias_records = [
          { name = "r1", type = "A", lbs_map_key = "private" },
          { name = "r2", type = "A", lbs_map_key = "private" },
          { name = "r3", type = "A", lbs_map_key = "private" },
          { name = "r4", type = "A", lbs_map_key = "private" },
        ]
      }
    }
  }
}



