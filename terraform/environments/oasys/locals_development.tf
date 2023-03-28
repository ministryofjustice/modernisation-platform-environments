# oasys-development environment specific settings
locals {
  development_config = {

    # cloud watch log groups
    log_groups = {
      session-manager-logs = {
        retention_days = 90
      }
      cwagent-var-log-messages = {
        retention_days = 30
      }
      cwagent-var-log-secure = {
        retention_days = 90
      }
      cwagent-oasys-autologoff = {
        retention_days = 90
      }
    }

    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    autoscaling_groups = { # currently this does nothing - add to baseline


      # development-oasys-db = merge(local.database, {
      #   tags = merge(local.database_tags, {
      #     oasys-environment = "development"
      #     server-type       = "oasys-db"
      #     description       = "Development OASys database"
      #     oracle-sids       = "OASPROD BIPINFRA"
      #     monitored         = true
      #   })
      #   ami_name = "oasys_oracle_db_*"
      #   # ami_owner = "self" # remove this line next time AMI is updated so core-shared-services-production used instead
      # })
    }

    # Add database instances here. They will be created using ec2-database.tf
    databases = { # currently this does nothing - add to baseline
      # development-oasys-db-1 = {
      #   tags = {
      #     oasys-environment = "development"
      #     server-type       = "oasys-db"
      #     description       = "Development OASys database"
      #     oracle-sids       = "OASPROD BIPINFRA"
      #     monitored         = true
      #   }
      #   ami_name = "oasys_oracle_db_*"
      #   # ami_owner = "self" # remove this line next time AMI is updated so core-shared-services-production used instead
      #   instance = {
      #     instance_type             = "r6i.2xlarge"
      #     disable_api_termination   = true
      #     metadata_endpoint_enabled = "enabled"
      #   }
      #   # ebs_volumes = {
      #   #   "/dev/sdb" = { size = 100 }
      #   #   "/dev/sdc" = { size = 100 }
      #   # }
      #   # ebs_volume_config = {
      #   #   data  = { total_size = 200 }
      #   #   flash = { total_size = 50 }
      #   # }
      # }

      # dev-onr-db-1 = {
      #   tags = {
      #     oasys-environment = "development"
      #     server-type       = "onr-db"
      #     description       = "Development ONR database"
      #     oracle-sids       = "onrbods ONRAUD ONRSYS MISTRANS OASYSREP"
      #     monitored         = true
      #   }
      #   ami_name = "onr_oracle_db_*"
      #   instance = {
      #     instance_type             = "r6i.xlarge"
      #     disable_api_termination   = true
      #     metadata_endpoint_enabled = "enabled"
      #   }
      #   ebs_volumes = {
      #     "/dev/sdb" = { size = 100 }
      #     "/dev/sdc" = { size = 5120 }
      #   }
      #   ebs_volume_config = {
      #     data  = { total_size = 4000 }
      #     flash = { total_size = 1000 }
      #   }
      # }
    }

    baseline_bastion_linux = {
      public_key_data = local.public_key_data.keys[local.environment]
      tags            = local.tags
    }


    baseline_s3_buckets = {
    }

    baseline_ec2_instances = {

      # Example instance using RedHat image with ansible provisioning
      # dev-redhat-rhel79-1 = {
      #   config = merge(module.baseline_presets.ec2_instance.config.default, {
      #     ami_name  = "RHEL-7.9_HVM-*"
      #     ami_owner = "309956199498"
      #   })
      #   instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      #     vpc_security_group_ids = ["private"]
      #   })
      #   user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
      #   tags = {
      #     description = "For testing with official RedHat RHEL7.9 image"
      #     os-type     = "Linux"
      #     component   = "test"
      #     server-type = "set me to the ansible server type group vars"
      #   }
      # }

      # Example instance using base image with ansible provisioning
      # dev-base-rhel79-1 = {
      #   config = merge(module.baseline_presets.ec2_instance.config.default, {
      #     ami_name = "base_rhel_7_9_*"
      #   })
      #   instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      #     vpc_security_group_ids = ["private"]
      #   })
      #   user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
      #   tags = {
      #     description = "For testing with official RedHat RHEL7.9 image"
      #     os-type     = "Linux"
      #     component   = "test"
      #     server-type = "set me to the ansible server type group vars"
      #   }
      # }
    }

    baseline_ec2_autoscaling_groups = {

      # Example ASG using base image with ansible provisioning
      # Include the autoscale-trigger-hook ansible role when using hooks
      # development-oasys-web = {
      #   config = merge(module.baseline_presets.ec2_instance.config.default, {
      #     ami_name = "oasys_webserver_*"
      #   })
      #   instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      #     vpc_security_group_ids = ["private"]
      #   })
      #   user_data_cloud_init = {
      #     args = {
      #       lifecycle_hook_name  = "ready-hook"
      #       branch               = "main"
      #       ansible_repo         = "modernisation-platform-configuration-management"
      #       ansible_repo_basedir = "ansible"
      #       ansible_args         = ""
      #     }
      #     scripts = [
      #       "install-ssm-agent.sh.tftpl",
      #       "ansible-ec2provision.sh.tftpl",
      #       "post-ec2provision.sh.tftpl"
      #     ]
      #   }
      #   autoscaling_group = {
      #     desired_capacity    = 1
      #     max_size            = 2
      #     vpc_zone_identifier = module.environment.subnets["private"].ids
      #   }
      #   autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
      #   tags = {
      #     os-type           = "Linux"
      #     oasys-environment = "t1"
      #     description       = "oasys webserver"
      #     component         = "web"
      #     server-type       = "oasys-web"
      #     os-version        = "RHEL 7.9"
      #   }

      #   # Example target group setup below

      #   lb_target_groups = {
      #     http-8080 = {
      #       port                 = 8080
      #       protocol             = "HTTP"
      #       target_type          = "instance"
      #       deregistration_delay = 30
      #       health_check = {
      #         enabled             = true
      #         interval            = 30
      #         healthy_threshold   = 3
      #         matcher             = "200-399"
      #         path                = "/"
      #         port                = 8080
      #         timeout             = 5
      #         unhealthy_threshold = 5
      #       }
      #       stickiness = {
      #         enabled = true
      #         type    = "lb_cookie"
      #       }
      #     }
      #   }
      # }
    }

    baseline_lbs = {
      #
      # Below is an example of a baseline load balancer setup
      #
      #   rhel85-test = {
      #     enable_delete_protection = false
      #     idle_timeout             = "60"
      #     public_subnets           = module.environment.subnets["public"].ids
      #     force_destroy_bucket     = true
      #     internal_lb              = true
      #     tags                     = local.tags
      #     security_groups          = [module.baseline.security_groups["public"].id]
      #     listeners = {
      #       https = {
      #         port             = 443
      #         protocol         = "HTTPS"
      #         ssl_policy       = "ELBSecurityPolicy-2016-08"
      #         certificate_arns = [module.acm_certificate["star.${module.environment.domains.public.application_environment}"].arn]
      #         default_action = {
      #           type = "fixed-response"
      #           fixed_response = {
      #             content_type = "text/plain"
      #             message_body = "Not implemented"
      #             status_code  = "501"
      #           }
      #         }

      #         rules = {
      #           forward-http-8080 = {
      #             priority = 100
      #             actions = [{
      #               type              = "forward"
      #               target_group_name = "http-8080"
      #             }]
      #             conditions = [
      #               {
      #                 host_header = {
      #                   values = ["web.oasys.${module.environment.vpc_name}.modernisation-platform.service.justice.gov.uk"]
      #                 }
      #               },
      #               {
      #                 path_pattern = {
      #                   values = ["/"]
      #                 }
      #             }]
      #           }
      #         }
      #       }
      #       route53_records = {
      #         "web.oasys" = {
      #           account                = "core-vpc"
      #           zone_id                = module.environment.route53_zones[module.environment.domains.public.business_unit_environment].zone_id
      #           evaluate_target_health = true
      #         }
      #       }
      #     }
      #   }
    }
  }
}
