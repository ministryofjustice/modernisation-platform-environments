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
      }
    }

    baseline_lbs = {
      r12 = {
        internal_lb              = true
        enable_delete_protection = false
        load_balancer_type       = "network"
        force_destroy_bucket     = true
        subnets = [
          module.environment.subnet["private"]["eu-west-2a"].id,
          module.environment.subnet["private"]["eu-west-2b"].id,
        ]
        security_groups                  = ["load-balancer"]
        access_logs                      = false
        enable_cross_zone_load_balancing = true

        instance_target_groups = {
          rds-connection-broker-80 = {
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
            #  { ec2_instance_name = "rds-connection-broker-a" },
            #  { ec2_instance_name = "rds-connection-broker-c" },
            #]
          }
          rds-connection-broker-7770 = {
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
            #  { ec2_instance_name = "rds-connection-broker-a" },
            #  { ec2_instance_name = "rds-connection-broker-c" },
            #]
          }
          rds-connection-broker-7771 = {
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
            #  { ec2_instance_name = "rds-connection-broker-a" },
            #  { ec2_instance_name = "rds-connection-broker-c" },
            #]
          }
          rds-connection-broker-7780 = {
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
            #  { ec2_instance_name = "rds-connection-broker-a" },
            #  { ec2_instance_name = "rds-connection-broker-c" },
            #]
          }
          rds-connection-broker-7781 = {
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
            #  { ec2_instance_name = "rds-connection-broker-a" },
            #  { ec2_instance_name = "rds-connection-broker-c" },
            #]
          }
        }

        listeners = {
          http = {
            port     = 80
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "rds-connection-broker-80"
            }
          }
          http-7770 = {
            port     = 7770
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "rds-connection-broker-7770"
            }
          }
          http-7771 = {
            port     = 7771
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "rds-connection-broker-7771"
            }
          }
          http-7780 = {
            port     = 7780
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "rds-connection-broker-7780"
            }
          }
          http-7781 = {
            port     = 7781
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "rds-connection-broker-7781"
            }
          }
        }
      }

      baseline_route53_zones = {
        "pp.csr.service.justice.gov.uk" = {
          lb_alias_records = [
            { name = "r1", type = "A", lbs_map_key = "r12" },
          ]
        }
      }
    }
  }
}
