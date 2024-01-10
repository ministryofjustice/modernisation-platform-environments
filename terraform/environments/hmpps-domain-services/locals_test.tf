locals {

  # baseline config
  test_config = {

    baseline_secretsmanager_secrets = {
      "/join_domain_linux_service_account" = {
        secrets = {
          passwords = {}
        }
      }
    }

    baseline_ec2_autoscaling_groups = {

      test-redhat-rhel85 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "hmpps_rhel_8_5*"
          ami_owner         = "161282055413"
          availability_zone = null
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-dc"]
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "main"
          })
        })
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "For testing connection to Azure domain"
          ami         = "${local.application_name}_rhel_8_5"
          os-type     = "Linux"
          component   = "test"
          server-type = local.application_name
        }
      },

      rds-connection-broker = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2023-*"
          availability_zone             = null
          ebs_volumes_copy_all_from_ami = false
          user_data_raw = base64encode(templatefile("./templates/rds.yaml.tftpl", {
            rds_hostname = "RDSBroker"
          }))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-dc"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0 # set to 0 while testing
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "Windows Server 2022 host for RDS connection broker role"
          os-type     = "Windows"
          component   = "RDS Connection Broker"
          server-type = "hmpps-windows_2022"
        }
      },

      rds-licensing = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2023-*"
          availability_zone             = null
          ebs_volumes_copy_all_from_ami = false
          user_data_raw = base64encode(templatefile("./templates/rds.yaml.tftpl", {
            rds_hostname = "RDSLicensing"
          }))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-dc"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0 # set to 0 while testing
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "Windows Server 2022 host for RDS licensing role"
          os-type     = "Windows"
          component   = "RDS Licensing"
          server-type = "hmpps-windows_2022"
        }
      },

      rds-web-access = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2023-*"
          availability_zone             = null
          ebs_volumes_copy_all_from_ami = false
          user_data_raw = base64encode(templatefile("./templates/rds.yaml.tftpl", {
            rds_hostname = "RDSWebAccess"
          }))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-dc"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0 # set to 0 while testing
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "Windows Server 2022 host for RDS web access role"
          os-type     = "Windows"
          component   = "RDS Web Access"
          server-type = "hmpps-windows_2022"
        }
      },

      rds-gateway = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2023-*"
          availability_zone             = null
          ebs_volumes_copy_all_from_ami = false
          user_data_raw = base64encode(templatefile("./templates/rds.yaml.tftpl", {
            rds_hostname = "RDSGateway"
          }))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-dc"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0 # set to 0 while testing
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "Windows Server 2022 host for RDS gateway"
          os-type     = "Windows"
          component   = "RDS Gateway"
          server-type = "hmpps-windows_2022"
        }
      },

      rds-session-host = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2023-*"
          availability_zone             = null
          ebs_volumes_copy_all_from_ami = false
          user_data_raw = base64encode(templatefile("./templates/rds.yaml.tftpl", {
            rds_hostname = "RDSSessionHost"
          }))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-dc"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0 # set to 0 while testing
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "Windows Server 2022 host for RDS session host"
          os-type     = "Windows"
          component   = "RDS Session Host"
          server-type = "hmpps-windows_2022"
        }
      }

      rds-session-host-2012 = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "base_windows_server_2012_r2_release_2024-01-01T00-00-47.679Z"
          availability_zone             = null
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = base64encode(file("./templates/windows_server_2022-user-data.yaml"))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["rds-ec2s"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
        }
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default_with_ready_hook, {
          desired_capacity = 1 # set to 0 while testing
        })
        tags = {
          description = "Remote Desktop Services 2012 test ASG"
          os-type     = "Windows"
          component   = "remotedesktop"
        }
      }
    }

    baseline_ec2_instances = {
      test-rds-3-b = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2023-12-02T00-00-15.711Z"
          availability_zone             = "eu-west-2b"
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = base64encode(file("./templates/windows_server_2022-user-data.yaml"))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["rds-ec2s"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        tags = {
          description = "Remote Desktop Services test server 3"
          os-type     = "Windows"
          component   = "remotedesktop"
        }
      }
      test-rds-4-b = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2023-12-02T00-00-15.711Z"
          availability_zone             = "eu-west-2a"
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = base64encode(file("./templates/windows_server_2022-user-data.yaml"))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["rds-ec2s"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        tags = {
          description = "Remote Desktop Services test server 4"
          os-type     = "Windows"
          component   = "remotedesktop"
        }
      }
      test-rds-5-a = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2023-12-02T00-00-15.711Z"
          availability_zone             = "eu-west-2b"
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = base64encode(file("./templates/windows_server_2022-user-data.yaml"))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["rds-ec2s"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        tags = {
          description = "Remote Desktop Services test server 5"
          os-type     = "Windows"
          component   = "remotedesktop"
        }
      }
      test-rds-6-a = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2023-12-02T00-00-15.711Z"
          availability_zone             = "eu-west-2a"
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = base64encode(file("./templates/windows_server_2022-user-data.yaml"))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["rds-ec2s"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        tags = {
          description = "Remote Desktop Services test server 6"
          os-type     = "Windows"
          component   = "remotedesktop"
        }
      }
      test-rds-7-a = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2023-12-02T00-00-15.711Z"
          availability_zone             = "eu-west-2b"
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = base64encode(file("./templates/windows_server_2022-user-data.yaml"))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["rds-ec2s"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        tags = {
          description = "Remote Desktop Services test server 7"
          os-type     = "Windows"
          component   = "remotedesktop"
        }
      }
    }

    baseline_lbs = {
      public = {
        access_logs                      = true
        enable_cross_zone_load_balancing = true
        enable_delete_protection         = false
        force_destroy_bucket             = true
        internal_lb                      = false
        load_balancer_type               = "application"
        security_groups                  = ["public-lb"]
        subnets = [
          module.environment.subnet["public"]["eu-west-2a"].id,
          module.environment.subnet["public"]["eu-west-2b"].id,
          module.environment.subnet["public"]["eu-west-2c"].id,
        ]

        instance_target_groups = {
          test-rdgateway-http4 = {
            port     = 80
            protocol = "HTTP"
            health_check = {
              enabled             = true
              interval            = 10
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 80
              timeout             = 5
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
            attachments = [
              { ec2_instance_name = "test-rds-4-b" },
            ]
          }
          test-rdweb-https6 = {
            port     = 443
            protocol = "HTTPS"
            health_check = {
              enabled             = true
              interval            = 10
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 443
              protocol            = "HTTPS"
              timeout             = 5
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
            attachments = [
              { ec2_instance_name = "test-rds-6-a" },
            ]
          }
          test-rdgateway-http5 = {
            port     = 80
            protocol = "HTTP"
            health_check = {
              enabled             = true
              interval            = 10
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 80
              timeout             = 5
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
            attachments = [
              { ec2_instance_name = "test-rds-5-a" },
            ]
          }
          test-rdgateway-http7 = {
            port     = 80
            protocol = "HTTP"
            health_check = {
              enabled             = true
              interval            = 10
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 80
              timeout             = 5
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
            attachments = [
              { ec2_instance_name = "test-rds-5-a" },
            ]
          }
          test-rdweb-https7 = {
            port     = 443
            protocol = "HTTPS"
            health_check = {
              enabled             = true
              interval            = 10
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 443
              protocol            = "HTTPS"
              timeout             = 5
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
            attachments = [
              { ec2_instance_name = "test-rds-7-a" },
            ]
          }
          test-rdgateway-http45 = {
            port     = 80
            protocol = "HTTP"
            health_check = {
              enabled             = true
              interval            = 10
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 80
              timeout             = 5
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
            attachments = [
              { ec2_instance_name = "test-rds-4-b" },
              { ec2_instance_name = "test-rds-5-a" },
            ]
          }
          test-rdweb-http67 = {
            port     = 443
            protocol = "HTTPS"
            health_check = {
              enabled             = true
              interval            = 10
              healthy_threshold   = 3
              matcher             = "200-399"
              path                = "/"
              port                = 443
              protocol            = "HTTPS"
              timeout             = 5
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "lb_cookie"
            }
            attachments = [
              { ec2_instance_name = "test-rds-6-a" },
              { ec2_instance_name = "test-rds-7-a" },
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
              test-rdgateway = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "test-rdgateway-http45"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "rdgateway.hmpps-domain-services.hmpps-test.modernisation-platform.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              test-rdweb = {
                priority = 400
                actions = [{
                  type              = "forward"
                  target_group_name = "test-rdweb-http67"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "rdweb.hmpps-domain-services.hmpps-test.modernisation-platform.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              test-rdgateway4 = {
                priority = 700
                actions = [{
                  type              = "forward"
                  target_group_name = "test-rdgateway-http4"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "rds.hmpps-domain-services.hmpps-test.modernisation-platform.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              test-rdgateway5 = {
                priority = 900
                actions = [{
                  type              = "forward"
                  target_group_name = "test-rdgateway-http5"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "rds2.hmpps-domain-services.hmpps-test.modernisation-platform.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              test-rdgateway7 = {
                priority = 901
                actions = [{
                  type              = "forward"
                  target_group_name = "test-rdgateway-http7"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "rdgateway2.hmpps-domain-services.hmpps-test.modernisation-platform.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              test-rdweb6 = {
                priority = 800
                actions = [{
                  type              = "forward"
                  target_group_name = "test-rdweb-https6"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "rdweb3.hmpps-domain-services.hmpps-test.modernisation-platform.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              test-rdweb7 = {
                priority = 999
                actions = [{
                  type              = "forward"
                  target_group_name = "test-rdweb-https7"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "rdweb4.hmpps-domain-services.hmpps-test.modernisation-platform.service.justice.gov.uk",
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
      "hmpps-test.modernisation-platform.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "rdgateway.hmpps-domain-services", type = "A", lbs_map_key = "public" },
          { name = "rdgateway2.hmpps-domain-services", type = "A", lbs_map_key = "public" },
          { name = "rdweb.hmpps-domain-services", type = "A", lbs_map_key = "public" },
          { name = "rds.hmpps-domain-services", type = "A", lbs_map_key = "public" },
          { name = "rds2.hmpps-domain-services", type = "A", lbs_map_key = "public" },
          { name = "rdweb3.hmpps-domain-services", type = "A", lbs_map_key = "public" },
          { name = "rdweb4.hmpps-domain-services", type = "A", lbs_map_key = "public" },
        ]
      }
    }
  }
}

