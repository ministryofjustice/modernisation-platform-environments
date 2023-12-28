# nomis-test environment settings
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
    }

    baseline_ec2_instances = {
      test-rds-1-a = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2023-12-02T00-00-15.711Z"
          availability_zone             = "eu-west-2a"
          ebs_volumes_copy_all_from_ami = false
          # user_data_raw                 = base64encode(file("./templates/windows_server_2022-user-data.yaml"))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["rds-ec2s"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        tags = {
          description = "Remote Desktop Gateway and Web Access Server"
          os-type     = "Windows"
          component   = "remotedesktop"
        }
      }
      test-rds-2-a = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2023-12-02T00-00-15.711Z"
          availability_zone             = "eu-west-2a"
          ebs_volumes_copy_all_from_ami = false
          # user_data_raw                 = base64encode(file("./templates/windows_server_2022-user-data.yaml"))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["rds-ec2s"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        tags = {
          description = "Remote Desktop License Manager and Session Broker"
          os-type     = "Windows"
          component   = "remotedesktop"
        }
      }
      test-rds-3-a = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2023-12-02T00-00-15.711Z"
          availability_zone             = "eu-west-2a"
          ebs_volumes_copy_all_from_ami = false
          # user_data_raw                 = base64encode(file("./templates/windows_server_2022-user-data.yaml"))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["rds-ec2s"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        tags = {
          description = "Test Remote Desktop Session Host"
          os-type     = "Windows"
          component   = "test"
        }
      }
    }

    baseline_lbs = {
      public = {
        access_logs                      = false
        enable_cross_zone_load_balancing = true
        enable_delete_protection         = false
        force_destroy_bucket             = true
        internal_lb                      = false
        load_balancer_type               = "application"
        security_groups                  = ["public-lb"]
        subnets = [
          module.environment.subnet["public"]["eu-west-2a"].id,
          module.environment.subnet["public"]["eu-west-2b"].id,
        ]

        instance_target_groups = {
          public-test-rds-1 = {
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
              { ec2_instance_name = "test-rds-1-a" },
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
              type              = "forward"
              target_group_name = "public-test-rds-1"
            }
          }
        }
      }
      private = {
        access_logs                      = false
        enable_cross_zone_load_balancing = true
        enable_delete_protection         = false
        force_destroy_bucket             = true
        internal_lb                      = true
        load_balancer_type               = "application"
        security_groups                  = ["private-lb"]
        subnets = [
          module.environment.subnet["private"]["eu-west-2a"].id,
          module.environment.subnet["private"]["eu-west-2b"].id,
        ]

        instance_target_groups = {
          test-rds-1 = {
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
              { ec2_instance_name = "test-rds-1-a" },
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
              type              = "forward"
              target_group_name = "test-rds-1"
            }
          }
        }
      }
    }

    baseline_route53_zones = {
      "hmpps-test.modernisation-platform.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "rdgateway-int.hmpps-domain-services", type = "A", lbs_map_key = "private" },
          { name = "rdweb-int.hmpps-domain-services", type = "A", lbs_map_key = "private" },
          { name = "rdgateway.hmpps-domain-services", type = "A", lbs_map_key = "public" },
          { name = "rdweb.hmpps-domain-services", type = "A", lbs_map_key = "public" },
        ]
      }
    }
  }
}

