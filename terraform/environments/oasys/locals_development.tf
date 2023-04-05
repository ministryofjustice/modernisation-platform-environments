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

    baseline_bastion_linux = {
      # public_key_data = local.public_key_data.keys[local.environment]
      # tags            = local.tags
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

      dev-oasys-db = merge(local.database, {
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags                  = local.database_tags
      })
    }

    baseline_lbs = {
      # AWS doesn't let us call it internal
      private = {
        internal_lb              = true
        enable_delete_protection = false
        existing_target_groups   = {
          development-oasys-web-http-8080 = local.lb_target_groups.http-8080
        }
        force_destroy_bucket     = true
        idle_timeout             = 3600
        public_subnets           = module.environment.subnets["private"].ids
        security_groups          = [module.baseline.security_groups["public"].id]

        listeners = {
          development-oasys-web-http-8080 = {
            port     = 8080
            protocol = "HTTP"
            default_action = {
              type              = "forward"
              target_group_name_replace     = "development-oasys-web"
              condition_host_header_replace = "development-oasys-web"
            }
          }
        }

        # public LB not needed right now
        # public = {
        #   internal_lb              = false
        #   enable_delete_protection = false
        #   force_destroy_bucket     = true
        #   idle_timeout             = 3600
        #   public_subnets           = module.environment.subnets["public"].ids
        #   security_groups          = [aws_security_group.public.id]
        # }
      }
    }
  }
}


