# nomis-test environment settings
locals {

  # baseline config
  test_config = {

    baseline_ssm_parameters = {
      "/join_domain_linux_service_account" = {
        parameters = {
          passwords = {}
        }
      }
    }
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
            rds_hostname = "RDSConnectionBroker"
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

    baseline_lbs = {
      networklb = {
        internal_lb              = true
        enable_delete_protection = false
        load_balancer_type       = "application"
        force_destroy_bucket     = true
        subnets = [
          module.environment.subnet["private"]["eu-west-2a"].id,
          module.environment.subnet["private"]["eu-west-2b"].id,
        ]
        security_groups                  = ["load-balancer"]
        access_logs                      = false
        enable_cross_zone_load_balancing = true

        instance_target_groups = {
          rds-gateway-80 = {
            port     = 80
            protocol = "TCP"
            health_check = {
              enabled             = true
              interval            = 5
              healthy_threshold   = 3
              port                = 80
              protocol            = "TCP"
              timeout             = 4
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "source_ip"
            }
            #attachments = [
            #  { ec2_instance_name = "rds-gateway" },
            #]
          }
          rds-gateway-7770 = {
            port     = 7770
            protocol = "TCP"
            health_check = {
              enabled             = true
              interval            = 5
              healthy_threshold   = 3
              path                = "/isps/index.html"
              port                = 7770
              protocol            = "HTTP"
              timeout             = 4
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "source_ip"
            }
            #attachments = [
            #  { ec2_instance_name = "rds-gateway" },
            #]
          }
          rds-gateway-7771 = {
            port     = 7771
            protocol = "TCP"
            health_check = {
              enabled             = true
              interval            = 5
              healthy_threshold   = 3
              path                = "/isps/index.html"
              port                = 7771
              protocol            = "HTTP"
              timeout             = 4
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "source_ip"
            }
            #attachments = [
            #  { ec2_instance_name = "rds-gateway" },
            #]
          }
          rds-gateway-7780 = {
            port     = 7780
            protocol = "TCP"
            health_check = {
              enabled             = true
              interval            = 5
              healthy_threshold   = 3
              path                = "/"
              port                = 7770
              protocol            = "HTTP"
              timeout             = 4
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "source_ip"
            }
            #attachments = [
            #  { ec2_instance_name = "rds-gateway" },
            #]
          }
          rds-gateway-7781 = {
            port     = 7781
            protocol = "TCP"
            health_check = {
              enabled             = true
              interval            = 5
              healthy_threshold   = 3
              path                = "/"
              port                = 7771
              protocol            = "HTTP"
              timeout             = 4
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "source_ip"
            }
            #attachments = [
            #  { ec2_instance_name = "rds-gateway" },
            #]
          }
        }

        listeners = {
          http = {
            port     = 80
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "rds-gateway-80"
            }
          }
          http-7770 = {
            port     = 7770
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "rds-gateway-7770"
            }
          }
          http-7771 = {
            port     = 7771
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "rds-gateway-7771"
            }
          }
          http-7780 = {
            port     = 7780
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "rds-gateway-7780"
            }
          }
          http-7781 = {
            port     = 7781
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "rds-gateway-7781"
            }
          }
        }
      }
    }

    baseline_route53_zones = {
      "test.hmpps-domain-services.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "networklb", type = "A", lbs_map_key = "networklb" },
        ]
      }
    }
  }
}

